-- ============================================================
-- MIGRATION: Revert WA Perca Take & Tambah Stok Batch Two Phase
-- Date: 2026-05-03
--
-- Tujuan:
-- Mengembalikan struktur WA notifications ke kondisi di 
-- 20260430210000_wa_api_fix.sql karena implementasi Two-Phase telah
-- di-revert. Menghapus tabel staging dan RPC finalisasi, mengembalikan
-- enqueue_wa_notification menjadi RETURNS VOID, serta mengembalikan
-- trg_enqueue_wa_perca_take dan fn_enqueue_wa_perca_take_grouped.
-- ============================================================

-- 1. Drop tabel staging dan RPC dari Two-Phase Architecture
DROP TABLE IF EXISTS public.wa_perca_pending_sessions CASCADE;
DROP FUNCTION IF EXISTS public.rpc_finalize_perca_take_session(UUID, UUID, DATE) CASCADE;
DROP TRIGGER IF EXISTS trg_record_perca_take_pending ON public.perca_transactions CASCADE;
DROP FUNCTION IF EXISTS public.trg_record_perca_take_pending() CASCADE;

DROP TABLE IF EXISTS public.wa_percas_stock_pending_sessions CASCADE;
DROP FUNCTION IF EXISTS public.rpc_finalize_percas_stock_session(UUID, DATE) CASCADE;
DROP TRIGGER IF EXISTS trg_record_percas_stock_pending ON public.percas_stock CASCADE;
DROP FUNCTION IF EXISTS public.trg_record_percas_stock_pending() CASCADE;

DROP FUNCTION IF EXISTS public.rpc_cleanup_zombie_wa_batches(INTEGER) CASCADE;

-- 2. Kembalikan enqueue_wa_notification menjadi RETURNS VOID
DROP FUNCTION IF EXISTS public.enqueue_wa_notification(TEXT, TEXT, UUID, TEXT, TEXT, TEXT, TEXT);

CREATE OR REPLACE FUNCTION public.enqueue_wa_notification(
  p_event_type TEXT,
  p_source_table TEXT,
  p_source_id UUID,
  p_recipient_role TEXT,
  p_recipient_phone TEXT,
  p_message TEXT,
  p_image_url TEXT DEFAULT NULL
) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_jid TEXT;
BEGIN
  v_jid := public.normalize_wa_jid(p_recipient_phone);

  IF v_jid IS NULL OR p_message IS NULL OR btrim(p_message) = '' THEN
    RETURN;
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
    NULLIF(btrim(p_image_url), '')
  );
END;
$$;

-- 3. Kembalikan worker function Perca Take dari 20260430210000
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
  v_manager RECORD;
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
          E'• %s | Jenis: %s | Berat: %s kg',
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
    E'📥 *Pengambilan Perca*\n\nTanggal: %s\nPenjahit: %s\nTotal Karung: %s\nTotal Berat: %s kg\n\n*Daftar Karung/Perca:*\n%s\n\nSilakan cek detail transaksi pada sistem.',
    p_date_entry::TEXT,
    COALESCE(v_tailor_name, '-'),
    v_rows_count::TEXT,
    COALESCE(v_total_weight, 0)::TEXT,
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

  FOR v_manager IN
    SELECT p.no_telp
    FROM public.profiles p
    WHERE p.role::text = 'manager'
      AND p.no_telp IS NOT NULL
      AND btrim(p.no_telp) <> ''
  LOOP
    PERFORM public.enqueue_wa_notification(
      'pengambilan_perca',
      'perca_transactions',
      v_latest_tx_id,
      'manager',
      v_manager.no_telp,
      v_msg
    );
    SELECT q.id INTO v_qid
    FROM public.wa_notification_queue q
    WHERE q.event_type = 'pengambilan_perca'
      AND q.source_table = 'perca_transactions'
      AND q.recipient_role = 'manager'
      AND q.recipient_phone = v_manager.no_telp
    ORDER BY q.created_at DESC
    LIMIT 1;

    IF v_qid IS NOT NULL THEN
      v_queue_ids := array_append(v_queue_ids, v_qid);
    END IF;
  END LOOP;

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
    PERFORM pg_sleep(2);
    PERFORM public.fn_enqueue_wa_perca_take_grouped(
      NEW.id_tailors,
      NEW.staff_id,
      NEW.date_entry,
      4
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

-- 4. Kembalikan worker function Perca Stock dari 20260417121500
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
      AND ps.created_at >= now() - make_interval(secs => GREATEST(COALESCE(p_time_window_seconds, 3), 1))
  ),
  agg AS (
    SELECT
      COUNT(*)::INT AS cnt,
      COALESCE(SUM(weight), 0) AS total_weight,
      string_agg(
        format(
          E'• %s | Jenis: %s | Berat: %s kg',
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
  FROM (
    SELECT ps.delivery_proof, ps.created_at
    FROM public.percas_stock ps
    WHERE ps.id_factory = p_factory_id
      AND ps.date_entry = p_date_entry
      AND ps.created_at >= now() - make_interval(secs => GREATEST(COALESCE(p_time_window_seconds, 3), 1))
      AND ps.delivery_proof IS NOT NULL
      AND btrim(ps.delivery_proof) <> ''
    ORDER BY ps.created_at DESC
    LIMIT 1
  ) p;

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
    PERFORM pg_sleep(2);

    PERFORM public.fn_enqueue_wa_percas_stock_grouped(
      NEW.id_factory,
      NEW.date_entry,
      4
    );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enqueue_wa_tambah_stok_perca ON public.percas_stock;
CREATE TRIGGER trg_enqueue_wa_tambah_stok_perca
  AFTER INSERT ON public.percas_stock
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_enqueue_wa_tambah_stok_perca();
