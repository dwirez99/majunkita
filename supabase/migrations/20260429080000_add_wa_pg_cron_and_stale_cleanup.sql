-- ============================================================
-- MIGRATION: Tambahkan pg_cron untuk WA notification processor
--            + jadwal stale cleanup terpisah
-- Date: 2026-04-29
--
-- Root causes "stuck at pending":
--   1) Tidak ada pg_cron job yang tersimpan di kode → Edge Function
--      process-wa-notification-queue TIDAK pernah dipanggil secara otomatis
--      kecuali jika didaftarkan manual di Supabase Dashboard.
--   2) Baris yang terjebak di status `processing` (akibat Edge Function timeout
--      atau crash) hanya dibersihkan secara probabilistik (5%) saat dequeue
--      berikutnya — bisa menunggu lama.
--   3) Tidak ada jadwal tersendiri untuk membersihkan stale rows.
--
-- Solusi migrasi ini:
--   1) Buat/perbarui pg_cron job yang memanggil Edge Function setiap menit.
--   2) Buat pg_cron job stale cleanup terpisah setiap 2 menit.
--   3) Perkecil default timeout stale dari 120 detik → 90 detik agar baris
--      `processing` yang terjebak lebih cepat terdeteksi.
--
-- Catatan:
--   - Ekstensi pg_cron harus diaktifkan dari Supabase Dashboard:
--     Settings → Database → Extensions → cron
--   - Ganti <<SUPABASE_PROJECT_REF>>, <<SERVICE_ROLE_KEY>>,
--     dan <<WA_QUEUE_SECRET>> dengan nilai proyek yang sebenarnya
--     sebelum menerapkan migrasi ini ke produksi.
--   - Jika pg_cron belum aktif, dua blok DO $$ ... $$ di bawah ini
--     akan di-skip secara aman (terbungkus BEGIN/EXCEPTION).
-- ============================================================

-- ------------------------------------------------------------
-- 1) Kurangi default timeout stale menjadi 90 detik
--    (edge function timeout Supabase Free ~60 s, jadi 90 s sudah aman)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.mark_stale_wa_notifications_failed(
  p_timeout_seconds INTEGER DEFAULT 90,
  p_batch_size INTEGER DEFAULT 100
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_timeout_seconds INTEGER := GREATEST(COALESCE(p_timeout_seconds, 90), 1);
  v_batch_size INTEGER := GREATEST(COALESCE(p_batch_size, 100), 1);
  v_updated_count INTEGER := 0;
BEGIN
  WITH stale_ids AS (
    SELECT q.id
    FROM public.wa_notification_queue q
    WHERE
      (
        q.status = 'processing'
        AND COALESCE(q.updated_at, q.created_at) <= now() - make_interval(secs => v_timeout_seconds)
      )
    ORDER BY COALESCE(q.updated_at, q.created_at) ASC
    LIMIT v_batch_size
    FOR UPDATE SKIP LOCKED
  )
  UPDATE public.wa_notification_queue q
  SET
    status = CASE
      WHEN q.retry_count + 1 >= q.max_retries THEN 'failed'
      ELSE 'pending'
    END,
    retry_count = q.retry_count + 1,
    next_attempt_at = CASE
      WHEN q.retry_count + 1 >= q.max_retries THEN q.next_attempt_at
      ELSE now() + make_interval(secs => LEAST(POWER(2, GREATEST(q.retry_count, 0))::INT * 60, 3600))
    END,
    last_error = CASE
      WHEN q.last_error IS NULL OR btrim(q.last_error) = ''
        THEN format('System Timeout (%s s): stuck in processing', v_timeout_seconds)
      ELSE q.last_error || format(' | Timeout after %s s (processing)', v_timeout_seconds)
    END,
    processed_at = CASE
      WHEN q.retry_count + 1 >= q.max_retries THEN COALESCE(q.processed_at, now())
      ELSE NULL
    END,
    updated_at = now()
  FROM stale_ids
  WHERE q.id = stale_ids.id;

  GET DIAGNOSTICS v_updated_count = ROW_COUNT;
  RETURN v_updated_count;
END;
$$;

COMMENT ON FUNCTION public.mark_stale_wa_notifications_failed(INTEGER, INTEGER) IS
  'Menandai baris wa_notification_queue yang terjebak di processing sebagai pending (retryable) atau failed (max retries habis). Default timeout 90 detik.';

REVOKE EXECUTE ON FUNCTION public.mark_stale_wa_notifications_failed(INTEGER, INTEGER) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.mark_stale_wa_notifications_failed(INTEGER, INTEGER) TO service_role;

-- ------------------------------------------------------------
-- 2) Tingkatkan probabilitas cleanup di dequeue dari 5% → 25%
--    agar stale rows lebih cepat terdeteksi saat Edge Function polling
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.dequeue_wa_notifications(p_batch_size INTEGER DEFAULT 20)
RETURNS TABLE (
  id BIGINT,
  event_type TEXT,
  source_table TEXT,
  source_id UUID,
  recipient_role TEXT,
  recipient_phone TEXT,
  message TEXT,
  image_url TEXT,
  retry_count INTEGER,
  max_retries INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Leaky bucket: cleanup ~25% dari polling (naik dari 5%) agar
  -- baris processing yang stuck lebih cepat direset
  IF (random() < 0.25) THEN
    PERFORM public.mark_stale_wa_notifications_failed(90, 100);
  END IF;

  RETURN QUERY
  WITH picked AS (
    SELECT q.id
    FROM public.wa_notification_queue q
    WHERE q.status = 'pending'
      AND q.next_attempt_at <= now()
      AND q.retry_count < q.max_retries
    ORDER BY q.created_at ASC
    LIMIT GREATEST(COALESCE(p_batch_size, 20), 1)
    FOR UPDATE SKIP LOCKED
  )
  UPDATE public.wa_notification_queue q
  SET
    status = 'processing',
    updated_at = now()
  FROM picked
  WHERE q.id = picked.id
  RETURNING
    q.id,
    q.event_type,
    q.source_table,
    q.source_id,
    q.recipient_role,
    q.recipient_phone,
    q.message,
    q.image_url,
    q.retry_count,
    q.max_retries;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.dequeue_wa_notifications(INTEGER) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.dequeue_wa_notifications(INTEGER) TO service_role;

COMMENT ON FUNCTION public.dequeue_wa_notifications(INTEGER) IS
  'Mengambil batch WA queue pending. Cleanup stale probabilistik ditingkatkan ke 25% untuk mengurangi stale lag.';

-- ------------------------------------------------------------
-- 3) Fungsi RPC terpisah untuk pg_cron stale cleanup
--    (dipanggil langsung oleh pg_cron, tanpa HTTP overhead)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.rpc_cron_cleanup_stale_wa_notifications()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INTEGER;
BEGIN
  v_count := public.mark_stale_wa_notifications_failed(90, 200);
  RETURN format('Cleaned up %s stale WA notifications at %s', v_count, now());
END;
$$;

REVOKE EXECUTE ON FUNCTION public.rpc_cron_cleanup_stale_wa_notifications() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_cron_cleanup_stale_wa_notifications() TO service_role;

COMMENT ON FUNCTION public.rpc_cron_cleanup_stale_wa_notifications() IS
  'Dipanggil oleh pg_cron setiap 2 menit untuk membersihkan baris processing yang terjebak.';

-- ------------------------------------------------------------
-- 4) Daftarkan pg_cron jobs (membutuhkan ekstensi pg_cron aktif)
--
--    JOB 1: Panggil Edge Function process-wa-notification-queue setiap menit
--    JOB 2: Jalankan stale cleanup langsung via SQL setiap 2 menit
--
--    GANTI placeholder sebelum deploy ke produksi:
--      <<SUPABASE_PROJECT_REF>>  → project ref Anda (misal: abcdefghijklmnop)
--      <<SERVICE_ROLE_KEY>>      → service_role JWT dari Settings > API
--      <<WA_QUEUE_SECRET>>       → nilai WA_QUEUE_SECRET di Edge Function secrets
-- ------------------------------------------------------------
DO $$
BEGIN
  -- Cek apakah ekstensi pg_cron tersedia
  IF EXISTS (
    SELECT 1 FROM pg_extension WHERE extname = 'pg_cron'
  ) THEN

    -- Hapus job lama jika ada (idempoten)
    PERFORM cron.unschedule('wa-notification-processor')
    FROM cron.job WHERE jobname = 'wa-notification-processor';

    PERFORM cron.unschedule('wa-stale-cleanup')
    FROM cron.job WHERE jobname = 'wa-stale-cleanup';

    -- JOB 1: Trigger Edge Function setiap menit via pg_net HTTP call
    -- Membutuhkan ekstensi pg_net (tersedia di Supabase Pro ke atas)
    -- Untuk Supabase Free, gunakan external scheduler (cron job di server/laptop)
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_net') THEN
      PERFORM cron.schedule(
        'wa-notification-processor',
        '* * * * *',  -- setiap menit
        $$
          SELECT net.http_post(
            url     => 'https://<<SUPABASE_PROJECT_REF>>.supabase.co/functions/v1/process-wa-notification-queue',
            headers => jsonb_build_object(
              'Content-Type',    'application/json',
              'Authorization',   'Bearer <<SERVICE_ROLE_KEY>>',
              'x-queue-secret',  '<<WA_QUEUE_SECRET>>'
            ),
            body    => '{"batch_size": 20}'::jsonb
          );
        $$
      );
    END IF;

    -- JOB 2: Stale cleanup langsung via SQL setiap 2 menit
    PERFORM cron.schedule(
      'wa-stale-cleanup',
      '*/2 * * * *',  -- setiap 2 menit
      $cron$
        SELECT public.rpc_cron_cleanup_stale_wa_notifications();
      $cron$
    );

  END IF;
EXCEPTION WHEN OTHERS THEN
  -- pg_cron tidak tersedia atau error konfigurasi; skip dengan aman
  RAISE WARNING 'pg_cron setup skipped: %', SQLERRM;
END;
$$;
