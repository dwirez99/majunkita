-- ============================================================
-- MIGRATION: Fix WA Perca-Take Batching v2
-- Date: 2026-05-03
--
-- Tujuan:
--   Memperbaiki tiga masalah utama pada sistem notifikasi WA
--   pengambilan perca yang menyebabkan 1 scan menghasilkan
--   beberapa pesan terpisah (1-2 karung per pesan):
--
-- Fix 1: Filter Claimed Transactions pada CTE `picked`
--   - Sebelum: CTE picked hanya cek time-window, tidak peduli
--     apakah transaksi sudah masuk ke batch yang sedang/sudah
--     diproses (status 'processing' atau 'sent').
--   - Sesudah: Exclude setiap perca_transactions.id yang sudah
--     ada di dalam kolom source_transaction_ids pada batch
--     berstatus 'processing' atau 'sent'. Ini menghentikan
--     "shifting batch key" di mana scan 3 karung menghasilkan
--     3 pesan terpisah.
--
-- Fix 2: enqueue_wa_notification RETURNS BIGINT
--   - Sebelum: RETURNS VOID, lalu worker menebak id queue
--     dengan ORDER BY created_at DESC LIMIT 1 (race condition).
--   - Sesudah: INSERT ... RETURNING id; fungsi mengembalikan
--     BIGINT tepat, tidak ada tebak-tebakan.
--
-- Fix 3: Zombie Processing Cleanup
--   - Sebelum: Batch stuck di status 'processing' > 5 menit
--     memblokir seterusnya karena ON CONFLICT DO NOTHING.
--   - Sesudah: Sebelum klaim batch, reset zombie batches ke
--     'failed' agar karung bisa di-enqueue ulang.
--     Ditambah RPC publik rpc_cleanup_zombie_wa_batches untuk
--     dipanggil manual / cron.
-- ============================================================


-- ============================================================
-- FIX 1 + FIX 2: Ganti enqueue_wa_notification menjadi RETURNS BIGINT
-- ============================================================

-- Hapus function lama (signature VOID), ganti dengan BIGINT
DROP FUNCTION IF EXISTS public.enqueue_wa_notification(TEXT, TEXT, UUID, TEXT, TEXT, TEXT, TEXT);

CREATE OR REPLACE FUNCTION public.enqueue_wa_notification(
  p_event_type    TEXT,
  p_source_table  TEXT,
  p_source_id     UUID,
  p_recipient_role TEXT,
  p_recipient_phone TEXT,
  p_message       TEXT,
  p_image_url     TEXT DEFAULT NULL
)
RETURNS BIGINT          -- <-- Fix 2: kembalikan id yang baru diinsert
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_jid    TEXT;
  v_new_id BIGINT;
BEGIN
  v_jid := public.normalize_wa_jid(p_recipient_phone);

  IF v_jid IS NULL OR p_message IS NULL OR btrim(p_message) = '' THEN
    RETURN NULL;
  END IF;

  INSERT INTO public.wa_notification_queue (
    event_type,
    source_table,
    source_id,
    recipient_role,
    recipient_phone,
    message,
    image_url
  ) VALUES (
    p_event_type,
    p_source_table,
    p_source_id,
    p_recipient_role,
    v_jid,
    p_message,
    NULLIF(btrim(COALESCE(p_image_url, '')), '')
  )
  RETURNING id INTO v_new_id;   -- <-- Fix 2: tangkap id langsung dari INSERT

  RETURN v_new_id;
END;
$$;

COMMENT ON FUNCTION public.enqueue_wa_notification(TEXT, TEXT, UUID, TEXT, TEXT, TEXT, TEXT) IS
  'Insert satu notifikasi WA ke queue dan kembalikan id-nya. RETURNS BIGINT (NULL jika tidak ter-insert).';

-- Pastikan caller lama (yang pakai PERFORM) tetap valid:
-- PERFORM masih bekerja untuk RETURNS BIGINT karena hasilnya dibuang.
-- Semua caller yang butuh id harus: v_qid := enqueue_wa_notification(...);


-- ============================================================
-- FIX 3: Zombie Cleanup RPC
--   Batch stuck 'processing' > 5 menit = zombie, reset ke 'failed'
-- ============================================================

CREATE OR REPLACE FUNCTION public.rpc_cleanup_zombie_wa_batches(
  p_timeout_minutes INTEGER DEFAULT 5
)
RETURNS INTEGER   -- jumlah baris yang direset
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INTEGER;
BEGIN
  UPDATE public.wa_perca_take_batches
  SET
    status    = 'failed',
    last_error = format(
      'Zombie: masih processing setelah %s menit (created_at: %s)',
      p_timeout_minutes,
      created_at::TEXT
    ),
    processed_at = now()
  WHERE status = 'processing'
    AND created_at < now() - make_interval(mins => COALESCE(p_timeout_minutes, 5));

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

COMMENT ON FUNCTION public.rpc_cleanup_zombie_wa_batches(INTEGER) IS
  'Reset wa_perca_take_batches yang stuck "processing" lebih dari N menit ke status "failed". Dapat dipanggil manual atau via cron.';

REVOKE EXECUTE ON FUNCTION public.rpc_cleanup_zombie_wa_batches(INTEGER) FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.rpc_cleanup_zombie_wa_batches(INTEGER) TO service_role;


-- ============================================================
-- FIX 1 + FIX 2 + FIX 3: Revisi worker utama
--   fn_enqueue_wa_perca_take_grouped
-- ============================================================

CREATE OR REPLACE FUNCTION public.fn_enqueue_wa_perca_take_grouped(
  p_tailor_id           UUID,
  p_staff_id            UUID,
  p_date_entry          DATE,
  p_time_window_seconds INTEGER DEFAULT 4
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_manager        RECORD;
  v_tailor_name    TEXT;
  v_tailor_phone   TEXT;
  v_rows_count     INTEGER   := 0;
  v_total_weight   NUMERIC   := 0;
  v_details        TEXT      := '';
  v_batch_key      TEXT;
  v_source_ids     UUID[]    := '{}'::UUID[];
  v_latest_tx_id   UUID;
  v_queue_ids      BIGINT[]  := '{}'::BIGINT[];
  v_qid            BIGINT;
  v_msg            TEXT;
  v_claimed_ids    UUID[]    := '{}'::UUID[];   -- ids yang sudah diklaim batch lain
BEGIN

  -- ----------------------------------------------------------
  -- Fix 3 (inline): bersihkan zombie sebelum klaim batch baru
  -- ----------------------------------------------------------
  PERFORM public.rpc_cleanup_zombie_wa_batches(5);

  -- ----------------------------------------------------------
  -- Ambil identitas penjahit
  -- ----------------------------------------------------------
  SELECT t.name, t.no_telp
  INTO   v_tailor_name, v_tailor_phone
  FROM   public.tailors t
  WHERE  t.id = p_tailor_id;

  -- ----------------------------------------------------------
  -- Fix 1: Kumpulkan semua transaction id yang SUDAH diklaim
  --   oleh batch berstatus 'processing' atau 'sent'.
  --   Cara: unnest source_transaction_ids dari semua batch aktif
  --   untuk tailor + date yang sama.
  -- ----------------------------------------------------------
  SELECT COALESCE(
    array_agg(unnested_id ORDER BY unnested_id),
    '{}'::UUID[]
  )
  INTO v_claimed_ids
  FROM (
    SELECT UNNEST(b.source_transaction_ids) AS unnested_id
    FROM   public.wa_perca_take_batches b
    WHERE  b.tailor_id   = p_tailor_id
      AND  b.date_entry  = p_date_entry
      AND  b.status IN ('processing', 'sent')
  ) sub;

  -- ----------------------------------------------------------
  -- Pilih transaksi dalam time-window yang BELUM diklaim
  -- Fix 1: tambah filter NOT (pt.id = ANY(v_claimed_ids))
  -- ----------------------------------------------------------
  WITH picked AS (
    SELECT
      pt.id,
      pt.id_stock_perca,
      COALESCE(pt.percas_type, ps.perca_type, '-')  AS perca_type,
      COALESCE(pt.weight, ps.weight, 0)              AS weight,
      ps.sack_code,
      pt.created_at
    FROM  public.perca_transactions pt
    LEFT JOIN public.percas_stock ps
           ON ps.id = pt.id_stock_perca
    WHERE pt.id_tailors  = p_tailor_id
      AND COALESCE(pt.staff_id, p_staff_id) = p_staff_id
      AND pt.date_entry  = p_date_entry
      AND pt.created_at >= now() - make_interval(secs => GREATEST(COALESCE(p_time_window_seconds, 4), 1))
      -- Fix 1: abaikan transaksi yang sudah diklaim batch lain
      AND NOT (pt.id = ANY(v_claimed_ids))
  ),
  agg AS (
    SELECT
      COUNT(*)::INT AS cnt,
      COALESCE(SUM(weight), 0) AS total_weight,
      string_agg(
        format(
          E'\u2022 %s | Jenis: %s | Berat: %s kg',
          COALESCE(sack_code, '-'),
          COALESCE(perca_type, '-'),
          COALESCE(weight, 0)::TEXT
        ),
        E'\n'
        ORDER BY created_at ASC
      ) AS details,
      array_agg(id ORDER BY created_at ASC) AS source_ids
    FROM picked
  )
  SELECT
    a.cnt,
    a.total_weight,
    COALESCE(a.details, ''),
    COALESCE(a.source_ids, '{}'::UUID[]),
    -- latest tx id untuk source_id pada wa_notification_queue
    (
      SELECT pt2.id
      FROM   public.perca_transactions pt2
      WHERE  pt2.id_tailors = p_tailor_id
        AND  COALESCE(pt2.staff_id, p_staff_id) = p_staff_id
        AND  pt2.date_entry  = p_date_entry
        AND  NOT (pt2.id = ANY(v_claimed_ids))
      ORDER BY pt2.created_at DESC
      LIMIT 1
    )
  INTO
    v_rows_count,
    v_total_weight,
    v_details,
    v_source_ids,
    v_latest_tx_id
  FROM agg a;

  -- Tidak ada transaksi baru yang belum diklaim → stop
  IF COALESCE(v_rows_count, 0) = 0 THEN
    RETURN;
  END IF;

  -- ----------------------------------------------------------
  -- Batch key deterministik berbasis daftar tx id yang TEPAT
  -- ----------------------------------------------------------
  v_batch_key := md5(
    'perca_take|' ||
    COALESCE(p_tailor_id::TEXT,  '-') || '|' ||
    COALESCE(p_staff_id::TEXT,   '-') || '|' ||
    COALESCE(p_date_entry::TEXT, '-') || '|' ||
    COALESCE(array_to_string(v_source_ids, ','), '')
  );

  -- ----------------------------------------------------------
  -- Klaim batch (idempotency hard guard)
  -- ON CONFLICT DO NOTHING: jika batch_key sudah ada → stop
  -- ----------------------------------------------------------
  INSERT INTO public.wa_perca_take_batches (
    batch_key,
    tailor_id,
    staff_id,
    date_entry,
    tx_count,
    total_weight,
    source_transaction_ids,
    status
  )
  VALUES (
    v_batch_key,
    p_tailor_id,
    p_staff_id,
    p_date_entry,
    v_rows_count,
    v_total_weight,
    v_source_ids,
    'processing'
  )
  ON CONFLICT (batch_key) DO NOTHING;

  -- Batch sudah/sedang diproses (oleh worker lain) → stop
  IF NOT FOUND THEN
    RETURN;
  END IF;

  -- ----------------------------------------------------------
  -- Susun isi pesan (satu pesan untuk semua karung dalam batch)
  -- ----------------------------------------------------------
  v_msg := format(
    E'📥 *Pengambilan Perca*\n\nTanggal: %s\nPenjahit: %s\nTotal Karung: %s\nTotal Berat: %s kg\n\n*Daftar Karung/Perca:*\n%s\n\nSilakan cek detail transaksi pada sistem.',
    p_date_entry::TEXT,
    COALESCE(v_tailor_name, '-'),
    v_rows_count::TEXT,
    COALESCE(v_total_weight, 0)::TEXT,
    v_details
  );

  -- ----------------------------------------------------------
  -- Kirim ke penjahit (jika punya nomor)
  -- Fix 2: gunakan RETURNS BIGINT, tidak perlu SELECT sesudahnya
  -- ----------------------------------------------------------
  IF v_tailor_phone IS NOT NULL AND btrim(v_tailor_phone) <> '' THEN
    v_qid := public.enqueue_wa_notification(
      'pengambilan_perca',
      'perca_transactions',
      v_latest_tx_id,
      'penjahit',
      v_tailor_phone,
      v_msg
    );
    IF v_qid IS NOT NULL THEN
      v_queue_ids := array_append(v_queue_ids, v_qid);
    END IF;
  END IF;

  -- ----------------------------------------------------------
  -- Kirim ke semua manager
  -- Fix 2: gunakan RETURNS BIGINT secara langsung
  -- ----------------------------------------------------------
  FOR v_manager IN
    SELECT p.no_telp
    FROM   public.profiles p
    WHERE  p.role::text = 'manager'
      AND  p.no_telp IS NOT NULL
      AND  btrim(p.no_telp) <> ''
  LOOP
    v_qid := public.enqueue_wa_notification(
      'pengambilan_perca',
      'perca_transactions',
      v_latest_tx_id,
      'manager',
      v_manager.no_telp,
      v_msg
    );
    IF v_qid IS NOT NULL THEN
      v_queue_ids := array_append(v_queue_ids, v_qid);
    END IF;
  END LOOP;

  -- Tandai batch sukses
  UPDATE public.wa_perca_take_batches b
  SET
    status               = 'sent',
    processed_at         = now(),
    notification_queue_ids = v_queue_ids,
    last_error           = NULL
  WHERE b.batch_key = v_batch_key;

EXCEPTION WHEN OTHERS THEN
  -- Tandai batch gagal + simpan pesan error
  UPDATE public.wa_perca_take_batches b
  SET
    status       = 'failed',
    processed_at = now(),
    last_error   = SQLERRM
  WHERE b.batch_key = v_batch_key;

  RAISE;
END;
$$;

COMMENT ON FUNCTION public.fn_enqueue_wa_perca_take_grouped(UUID, UUID, DATE, INTEGER) IS
  'Worker WA pengambilan perca v2: (1) filter transaksi yg sudah diklaim, (2) RETURNS BIGINT dari enqueue, (3) auto-cleanup zombie batches.';


-- ============================================================
-- Trigger function tetap sama, tidak perlu diubah
-- (sudah benar: pg_try_advisory_xact_lock + pg_sleep + call worker)
-- Tapi kita DROP & CREATE ulang agar attach ke definisi terbaru
-- ============================================================

CREATE OR REPLACE FUNCTION public.trg_enqueue_wa_perca_take()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_lock_key BIGINT;
BEGIN
  -- Advisory lock per (tailor, staff, date) agar hanya satu
  -- trigger instance dalam satu transaksi yang lolos.
  v_lock_key := hashtextextended(
    COALESCE(NEW.id_tailors::TEXT, '-') || '|' ||
    COALESCE(NEW.staff_id::TEXT,   '-') || '|' ||
    COALESCE(NEW.date_entry::TEXT, '-'),
    0
  );

  IF pg_try_advisory_xact_lock(v_lock_key) THEN
    -- Beri jeda agar INSERT batch lainnya selesai masuk DB
    -- sebelum worker membaca time-window
    PERFORM pg_sleep(2);
    PERFORM public.fn_enqueue_wa_perca_take_grouped(
      NEW.id_tailors,
      NEW.staff_id,
      NEW.date_entry,
      4   -- time window 4 detik
    );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enqueue_wa_perca_take ON public.perca_transactions;
CREATE TRIGGER trg_enqueue_wa_perca_take
  AFTER INSERT ON public.perca_transactions
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_enqueue_wa_perca_take();
