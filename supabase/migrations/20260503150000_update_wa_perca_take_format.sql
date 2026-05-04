-- ============================================================
-- MIGRATION: Update WA Perca Take Format
-- Date: 2026-05-03
--
-- Tujuan:
-- Memperbarui format pesan WA pada pengambilan perca agar 
-- persis sesuai dengan format yang diminta, yaitu:
-- *Pengambilan Perca*
-- Tanggal: ...
-- Nama Penjahit: ...
-- Total Karung: ...
-- *Daftar Karung/Perca:*
-- - sack-code | Jenis: ... | Berat: ... kg
-- ============================================================

CREATE OR REPLACE FUNCTION public.fn_enqueue_wa_perca_take_grouped(
  p_tailor_id UUID,
  p_staff_id UUID,
  p_date_entry DATE,
  p_time_window_seconds INTEGER DEFAULT 2
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
      AND COALESCE(pt.staff_id, p_staff_id) = p_staff_id
      AND pt.date_entry = p_date_entry
      AND pt.created_at >= now() - make_interval(secs => GREATEST(COALESCE(p_time_window_seconds, 2), 1))
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
        AND COALESCE(pt2.staff_id, p_staff_id) = p_staff_id
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
    COALESCE(p_staff_id::TEXT, '-') || '|' ||
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
