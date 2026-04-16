-- ============================================================
-- MIGRATION: Optimize stale WA cleanup (pending + processing -> failed)
-- Date: 2026-04-17
--
-- Tujuan:
--   1) Menandai antrian WA stale (pending/processing) menjadi failed
--      dengan batching agar tidak lock besar.
--   2) Mengurangi bottleneck polling dengan trigger cleanup probabilistik
--      di dequeue function.
--   3) Menambah partial index agar stale scan tetap cepat saat tabel membesar.
-- ============================================================

-- ------------------------------------------------------------
-- 0) Index untuk stale-cleanup performance
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_wa_queue_cleanup_stale
ON public.wa_notification_queue (status, updated_at, created_at)
WHERE status IN ('pending', 'processing');

-- ------------------------------------------------------------
-- 1) Helper function: mark stale rows as failed (batched)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.mark_stale_wa_notifications_failed(
  p_timeout_seconds INTEGER DEFAULT 120,
  p_batch_size INTEGER DEFAULT 100
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_timeout_seconds INTEGER := GREATEST(COALESCE(p_timeout_seconds, 120), 1);
  v_batch_size INTEGER := GREATEST(COALESCE(p_batch_size, 100), 1);
  v_updated_count INTEGER := 0;
BEGIN
  WITH stale_ids AS (
    SELECT q.id
    FROM public.wa_notification_queue q
    WHERE
      (
        q.status = 'pending'
        AND q.created_at <= now() - make_interval(secs => v_timeout_seconds)
      )
      OR
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
    status = 'failed',
    last_error = CASE
      WHEN q.last_error IS NULL OR btrim(q.last_error) = ''
        THEN format('System Timeout (%s s)', v_timeout_seconds)
      ELSE q.last_error || format(' | System Timeout after %s s', v_timeout_seconds)
    END,
    processed_at = COALESCE(q.processed_at, now()),
    updated_at = now()
  FROM stale_ids
  WHERE q.id = stale_ids.id;

  GET DIAGNOSTICS v_updated_count = ROW_COUNT;
  RETURN v_updated_count;
END;
$$;

COMMENT ON FUNCTION public.mark_stale_wa_notifications_failed(INTEGER, INTEGER) IS
  'Menandai wa_notification_queue stale (pending/processing) menjadi failed secara batched dengan SKIP LOCKED.';

REVOKE EXECUTE ON FUNCTION public.mark_stale_wa_notifications_failed(INTEGER, INTEGER) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.mark_stale_wa_notifications_failed(INTEGER, INTEGER) TO service_role;

-- ------------------------------------------------------------
-- 2) Integrasi dequeue RPC (probabilistic cleanup trigger)
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
  -- Leaky bucket: cleanup hanya ~5% dari polling untuk mengurangi write pressure
  IF (random() < 0.05) THEN
    PERFORM public.mark_stale_wa_notifications_failed(120, 100);
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
  'Mengambil batch WA queue pending untuk worker. Cleanup stale dipicu probabilistik (~5%) untuk menekan bottleneck polling.';

-- ------------------------------------------------------------
-- Catatan opsional produksi:
--   Untuk performa terbaik, cleanup idealnya dijalankan terpisah via scheduler (mis. pg_cron)
--   dan blok IF(random() < 0.05) di dequeue bisa dihapus.
-- ------------------------------------------------------------
