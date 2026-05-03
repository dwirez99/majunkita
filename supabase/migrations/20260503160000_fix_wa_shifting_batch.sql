-- ============================================================
-- MIGRATION: Fix WA Shifting Batch (Duplicate/Split Messages)
-- Date: 2026-05-03
--
-- Tujuan:
-- Menyelesaikan bug "shifting batch" di mana insert beruntun dari
-- aplikasi mengirimkan pesan terpecah-pecah. Solusinya:
-- 1. Mengubah query `picked` untuk mengambil HANYA baris yang belum 
--    pernah masuk ke tabel batch (`wa_perca_take_batches` & `wa_percas_stock_batches`).
-- 2. Menghapus batasan waktu statis (`now() - 2s`) sehingga berapapun lamanya
--    delay jaringan, selama belum ter-batch, akan dibungkus jadi 1 pesan utuh.
-- 3. Memperpanjang sleep dari 2s menjadi 3s di trigger untuk memastikan
--    semua koneksi concurrent dari Flutter sudah selesai insert.
-- ============================================================

-- ------------------------------------------------------------
-- 1. PENGAMBILAN PERCA (Tailor)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_enqueue_wa_perca_take_grouped(
  p_tailor_id UUID,
  p_staff_id UUID,
  p_date_entry DATE,
  p_time_window_seconds INTEGER DEFAULT 3
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tailor_name TEXT;
  v_tailor_phone TEXT;
  v_rows_count INTEGER := 0;
  v_total_weight NUMERIC := 0;
  v_details TEXT := '';
  v_batch_key TEXT;
  v_source_ids UUID[] := '{}'::UUID[];
  v_latest_tx_id UUID;
  v_queue_ids BIGINT[] := '{}'::BIGINT[];
  v_qid BIGINT;
  v_msg TEXT;
BEGIN
  SELECT t.name, t.no_telp
  INTO v_tailor_name, v_tailor_phone
  FROM public.tailors t
  WHERE t.id = p_tailor_id;

  WITH picked AS (
    SELECT
      pt.id,
      pt.id_stock_perca,
      COALESCE(pt.percas_type, ps.perca_type, '-') AS perca_type,
      COALESCE(pt.weight, ps.weight, 0) AS weight,
      ps.sack_code,
      pt.created_at
    FROM public.perca_transactions pt
    LEFT JOIN public.percas_stock ps
      ON ps.id = pt.id_stock_perca
    WHERE pt.id_tailors = p_tailor_id
      AND pt.date_entry = p_date_entry
      -- KUNCI FIX: Hanya ambil transaksi yang BELUM pernah di-batch
      AND NOT EXISTS (
        SELECT 1 FROM public.wa_perca_take_batches b
        WHERE pt.id = ANY(b.source_transaction_ids)
      )
  ),
  agg AS (
    SELECT
      COUNT(*)::INT AS cnt,
      COALESCE(SUM(weight), 0) AS total_weight,
      string_agg(
        format(
          E'- %s | Jenis: %s | Berat: %s kg',
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
    (
      SELECT pt2.id
      FROM public.perca_transactions pt2
      WHERE pt2.id_tailors = p_tailor_id
        AND pt2.date_entry = p_date_entry
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

  IF COALESCE(v_rows_count, 0) = 0 THEN
    RETURN;
  END IF;

  v_batch_key := md5(
    'perca_take|' ||
    COALESCE(p_tailor_id::TEXT, '-') || '|' ||
    COALESCE(p_date_entry::TEXT, '-') || '|' ||
    COALESCE(array_to_string(v_source_ids, ','), '')
  );

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

  IF NOT FOUND THEN
    RETURN;
  END IF;

  v_msg := format(
    E'*Pengambilan Perca*\n\nTanggal: %s\nNama Penjahit: %s\nTotal Karung: %s\n\n*Daftar Karung/Perca:*\n%s',
    p_date_entry::TEXT,
    COALESCE(v_tailor_name, '-'),
    v_rows_count::TEXT,
    v_details
  );

  IF v_tailor_phone IS NOT NULL AND btrim(v_tailor_phone) <> '' THEN
    PERFORM public.enqueue_wa_notification(
      'pengambilan_perca',
      'perca_transactions',
      v_latest_tx_id,
      'penjahit',
      v_tailor_phone,
      v_msg
    );
    SELECT q.id INTO v_qid
    FROM public.wa_notification_queue q
    WHERE q.event_type = 'pengambilan_perca'
      AND q.source_table = 'perca_transactions'
      AND q.recipient_role = 'penjahit'
      AND q.recipient_phone = v_tailor_phone
    ORDER BY q.created_at DESC
    LIMIT 1;

    IF v_qid IS NOT NULL THEN
      v_queue_ids := array_append(v_queue_ids, v_qid);
    END IF;
  END IF;

  UPDATE public.wa_perca_take_batches b
  SET
    status = 'sent',
    processed_at = now(),
    notification_queue_ids = v_queue_ids,
    last_error = NULL
  WHERE b.batch_key = v_batch_key;

EXCEPTION WHEN OTHERS THEN
  UPDATE public.wa_perca_take_batches b
  SET
    status = 'failed',
    processed_at = now(),
    last_error = SQLERRM
  WHERE b.batch_key = v_batch_key;
  RAISE;
END;
$$;

CREATE OR REPLACE FUNCTION public.trg_enqueue_wa_perca_take()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_lock_key BIGINT;
BEGIN
  v_lock_key := hashtextextended(
    COALESCE(NEW.id_tailors::TEXT, '-') || '|' ||
    COALESCE(NEW.staff_id::TEXT, '-') || '|' ||
    COALESCE(NEW.date_entry::TEXT, '-'),
    0
  );
  IF pg_try_advisory_xact_lock(v_lock_key) THEN
    -- PERPANJANG WAKTU TUNGGU MENJADI 3 DETIK AGAR SEMUA INSERT SELESAI
    PERFORM pg_sleep(3);
    PERFORM public.fn_enqueue_wa_perca_take_grouped(
      NEW.id_tailors,
      NEW.staff_id,
      NEW.date_entry,
      3
    );
  END IF;
  RETURN NEW;
END;
$$;

-- ------------------------------------------------------------
-- 2. TAMBAH STOK PERCA (Pabrik)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_enqueue_wa_percas_stock_grouped(
  p_factory_id UUID,
  p_date_entry DATE,
  p_time_window_seconds INTEGER DEFAULT 3
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_manager RECORD;
  v_factory_name TEXT;
  v_rows_count INTEGER := 0;
  v_total_weight NUMERIC := 0;
  v_details TEXT := '';
  v_image_url TEXT;
  v_batch_key TEXT;
  v_source_ids UUID[] := '{}'::UUID[];
  v_latest_stock_id UUID;
  v_queue_ids BIGINT[] := '{}'::BIGINT[];
  v_qid BIGINT;
  v_msg TEXT;
BEGIN
  SELECT f.factory_name
  INTO v_factory_name
  FROM public.factories f
  WHERE f.id = p_factory_id;

  WITH picked AS (
    SELECT
      ps.id,
      ps.perca_type,
      COALESCE(ps.weight, 0) AS weight,
      ps.sack_code,
      ps.delivery_proof,
      ps.created_at
    FROM public.percas_stock ps
    WHERE ps.id_factory = p_factory_id
      AND ps.date_entry = p_date_entry
      -- KUNCI FIX: Hanya ambil stok yang BELUM pernah di-batch
      AND NOT EXISTS (
        SELECT 1 FROM public.wa_percas_stock_batches b
        WHERE ps.id = ANY(b.source_stock_ids)
      )
  ),
  agg AS (
    SELECT
      COUNT(*)::INT AS cnt,
      COALESCE(SUM(weight), 0) AS total_weight,
      string_agg(
        format(
          E'- %s | Jenis: %s | Berat: %s kg',
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
    (
      SELECT ps2.id
      FROM public.percas_stock ps2
      WHERE ps2.id_factory = p_factory_id
        AND ps2.date_entry = p_date_entry
      ORDER BY ps2.created_at DESC
      LIMIT 1
    )
  INTO
    v_rows_count,
    v_total_weight,
    v_details,
    v_source_ids,
    v_latest_stock_id
  FROM agg a;

  IF COALESCE(v_rows_count, 0) = 0 THEN
    RETURN;
  END IF;

  v_batch_key := md5(
    'percas_stock|' ||
    COALESCE(p_factory_id::TEXT, '-') || '|' ||
    COALESCE(p_date_entry::TEXT, '-') || '|' ||
    COALESCE(array_to_string(v_source_ids, ','), '')
  );

  INSERT INTO public.wa_percas_stock_batches (
    batch_key,
    factory_id,
    date_entry,
    tx_count,
    total_weight,
    source_stock_ids,
    status
  )
  VALUES (
    v_batch_key,
    p_factory_id,
    p_date_entry,
    v_rows_count,
    v_total_weight,
    v_source_ids,
    'processing'
  )
  ON CONFLICT (batch_key) DO NOTHING;

  IF NOT FOUND THEN
    RETURN;
  END IF;

  SELECT p.delivery_proof
  INTO v_image_url
  FROM public.percas_stock p
  WHERE p.id = ANY(v_source_ids)
    AND p.delivery_proof IS NOT NULL
    AND btrim(p.delivery_proof) <> ''
  ORDER BY p.created_at DESC
  LIMIT 1;

  v_msg := format(
    E'📦 *Stok Perca Baru (Grouped)*\n\nAsal Pabrik: %s\nTanggal: %s\nTotal Karung: %s\nTotal Berat: %s kg\n\n*Daftar Perca:*\n%s\n\nSilakan cek detail stok pada sistem.',
    COALESCE(v_factory_name, '-'),
    p_date_entry::TEXT,
    v_rows_count::TEXT,
    COALESCE(v_total_weight, 0)::TEXT,
    v_details
  );

  FOR v_manager IN
    SELECT p.no_telp
    FROM public.profiles p
    WHERE p.role::text = 'manager'
      AND p.no_telp IS NOT NULL
      AND btrim(p.no_telp) <> ''
  LOOP
    PERFORM public.enqueue_wa_notification(
      'tambah_stok_perca_grouped',
      'percas_stock',
      v_latest_stock_id,
      'manager',
      v_manager.no_telp,
      v_msg,
      v_image_url
    );

    SELECT q.id
    INTO v_qid
    FROM public.wa_notification_queue q
    WHERE q.event_type = 'tambah_stok_perca_grouped'
      AND q.source_table = 'percas_stock'
      AND q.source_id = v_latest_stock_id
      AND q.recipient_role = 'manager'
      AND q.message = v_msg
      AND COALESCE(q.image_url, '') = COALESCE(v_image_url, '')
    ORDER BY q.created_at DESC, q.id DESC
    LIMIT 1;

    IF v_qid IS NOT NULL THEN
      v_queue_ids := array_append(v_queue_ids, v_qid);
    END IF;
  END LOOP;

  UPDATE public.wa_percas_stock_batches b
  SET
    status = 'sent',
    processed_at = now(),
    notification_queue_ids = v_queue_ids,
    last_error = NULL
  WHERE b.batch_key = v_batch_key;

EXCEPTION WHEN OTHERS THEN
  UPDATE public.wa_percas_stock_batches b
  SET
    status = 'failed',
    processed_at = now(),
    last_error = SQLERRM
  WHERE b.batch_key = v_batch_key;

  RAISE;
END;
$$;

CREATE OR REPLACE FUNCTION public.trg_enqueue_wa_tambah_stok_perca()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_lock_key BIGINT;
BEGIN
  v_lock_key := hashtextextended(
    COALESCE(NEW.id_factory::TEXT, '-') || '|' ||
    COALESCE(NEW.date_entry::TEXT, '-'),
    0
  );

  IF pg_try_advisory_xact_lock(v_lock_key) THEN
    -- PERPANJANG WAKTU TUNGGU MENJADI 3 DETIK AGAR SEMUA INSERT SELESAI
    PERFORM pg_sleep(3);

    PERFORM public.fn_enqueue_wa_percas_stock_grouped(
      NEW.id_factory,
      NEW.date_entry,
      3
    );
  END IF;

  RETURN NEW;
END;
$$;
