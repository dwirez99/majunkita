-- ============================================================
-- MIGRATION: Update WA Perca Take Format v3 & Anti-Split
-- Date: 2026-05-03
--
-- Tujuan:
-- 1. Mengelompokkan list karung berdasarkan kode karung, jenis, dan menghitung jumlah serta total berat per grup karung.
-- 2. Menyesuaikan format pesan persis dengan yang diminta.
-- 3. Memperpanjang sleep ke 5 detik untuk mengakomodasi jaringan yang lambat
--    saat mengirim multi-request dari Flutter agar tidak terpisah-pisah.
-- ============================================================

CREATE OR REPLACE FUNCTION public.fn_enqueue_wa_perca_take_grouped(
  p_tailor_id UUID,
  p_staff_id UUID,
  p_date_entry DATE,
  p_time_window_seconds INTEGER DEFAULT 5
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
      AND NOT EXISTS (
        SELECT 1 FROM public.wa_perca_take_batches b
        WHERE pt.id = ANY(b.source_transaction_ids)
      )
  ),
  agg_grouped AS (
    SELECT 
      sack_code,
      perca_type,
      COUNT(*)::INT as sack_count,
      SUM(weight) as total_weight_per_code,
      MIN(created_at) as min_created_at
    FROM picked
    GROUP BY sack_code, perca_type
  ),
  agg AS (
    SELECT
      SUM(sack_count)::INT AS cnt,
      SUM(total_weight_per_code) AS total_weight,
      string_agg(
        format(
          E'- %s | jenis: %s | Berat: %s KG Jumlah: %s karung',
          COALESCE(sack_code, '-'),
          COALESCE(perca_type, '-'),
          trim(to_char(COALESCE(total_weight_per_code, 0), 'FM999999999.00'), '.'),
          sack_count::TEXT
        ),
        E'\n'
        ORDER BY min_created_at ASC
      ) AS details
    FROM agg_grouped
  )
  SELECT
    a.cnt,
    a.total_weight,
    COALESCE(a.details, ''),
    (SELECT array_agg(id) FROM picked),
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
    E'*pengambilan perca oleh penjahit*\n\ntanggal = %s\nNama Penjahit = %s\ntotal karung = %s\ntotal berat = %s KG\n\n*Daftar karung*\n%s',
    to_char(p_date_entry, 'DD/MM/YYYY'),
    COALESCE(v_tailor_name, '-'),
    v_rows_count::TEXT,
    trim(to_char(COALESCE(v_total_weight, 0), 'FM999999999.00'), '.'),
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
    -- PERPANJANG WAKTU TUNGGU MENJADI 5 DETIK
    -- Agar tidak ada transaksi yang tertinggal karena network Flutter lambat
    PERFORM pg_sleep(5);
    PERFORM public.fn_enqueue_wa_perca_take_grouped(
      NEW.id_tailors,
      NEW.staff_id,
      NEW.date_entry,
      5
    );
  END IF;
  RETURN NEW;
END;
$$;
