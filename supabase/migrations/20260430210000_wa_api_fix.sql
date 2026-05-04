-- ============================================================
-- SQUASHED MIGRATION: WA Notifications, Profile Updates, Driver Permissions, Perca Batching
-- Date: 2026-04-30
-- ============================================================

-- 1) Role Authorization Functions
CREATE OR REPLACE FUNCTION public._check_is_admin_or_authorized()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role TEXT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT p.role::text INTO v_role
  FROM public.profiles p
  WHERE p.id = auth.uid();

  IF v_role IS NULL THEN
    RAISE EXCEPTION 'Forbidden: user profile not found';
  END IF;

  RETURN lower(btrim(v_role));
END;
$$;
COMMENT ON FUNCTION public._check_is_admin_or_authorized() IS 'Returns user role for authorization; allows any authenticated user';

CREATE OR REPLACE FUNCTION public._check_is_admin()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role TEXT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT p.role::text INTO v_role
  FROM public.profiles p
  WHERE p.id = auth.uid();

  IF v_role IS NULL OR lower(btrim(v_role)) <> 'admin' THEN
    RAISE EXCEPTION 'Forbidden: admin role required';
  END IF;
END;
$$;

-- 2) RLS POLICY: Allow authenticated users to update their own profile
DROP POLICY IF EXISTS "Users can update their own profile" ON "public"."profiles";
CREATE POLICY "Users can update their own profile"
  ON "public"."profiles"
  AS permissive
  FOR UPDATE
  TO authenticated
  USING ((auth.uid() = id))
  WITH CHECK ((auth.uid() = id));

-- 3) Notification View & Retry RPCs (Driver visibility for Perca and Expedition)
CREATE OR REPLACE FUNCTION public.rpc_get_wa_notifications(
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0,
  p_status TEXT DEFAULT NULL
)
RETURNS TABLE (
  id BIGINT,
  event_type TEXT,
  source_table TEXT,
  source_id UUID,
  recipient_role TEXT,
  recipient_phone TEXT,
  message TEXT,
  image_url TEXT,
  status TEXT,
  retry_count INTEGER,
  max_retries INTEGER,
  next_attempt_at TIMESTAMPTZ,
  last_error TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  processed_at TIMESTAMPTZ,
  last_log_response_status INTEGER,
  last_log_success BOOLEAN,
  last_log_error_message TEXT,
  last_log_response_body TEXT,
  last_log_created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_role TEXT;
BEGIN
  v_user_role := public._check_is_admin_or_authorized();

  RETURN QUERY
  SELECT
    q.id,
    q.event_type,
    q.source_table,
    q.source_id,
    q.recipient_role,
    q.recipient_phone,
    q.message,
    q.image_url,
    q.status,
    q.retry_count,
    q.max_retries,
    q.next_attempt_at,
    q.last_error,
    q.created_at,
    q.updated_at,
    q.processed_at,
    l.response_status,
    l.success,
    l.error_message,
    l.response_body,
    l.created_at
  FROM public.wa_notification_queue q
  LEFT JOIN LATERAL (
    SELECT wl.response_status, wl.success, wl.error_message, wl.response_body, wl.created_at
    FROM public.wa_notification_logs wl
    WHERE wl.queue_id = q.id
    ORDER BY wl.created_at DESC
    LIMIT 1
  ) l ON true
  WHERE (p_status IS NULL OR q.status = p_status)
    AND (
      v_user_role = 'admin' 
      OR q.recipient_role = v_user_role
      OR (v_user_role = 'driver' AND q.source_table IN ('percas_stock', 'perca_transactions', 'expeditions'))
    )
  ORDER BY q.created_at DESC
  LIMIT GREATEST(COALESCE(p_limit,50), 1)
  OFFSET GREATEST(COALESCE(p_offset,0), 0);
END;
$$;

CREATE OR REPLACE FUNCTION public.rpc_retry_wa_notification(p_queue_id BIGINT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_queue RECORD;
  v_user_role TEXT;
BEGIN
  v_user_role := public._check_is_admin_or_authorized();

  SELECT * INTO v_queue FROM public.wa_notification_queue WHERE id = p_queue_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Queue entry not found: %', p_queue_id;
  END IF;

  IF v_user_role <> 'admin' 
     AND v_queue.recipient_role <> v_user_role 
     AND NOT (v_user_role = 'driver' AND v_queue.source_table IN ('percas_stock', 'perca_transactions', 'expeditions')) 
  THEN
    RAISE EXCEPTION 'Forbidden: you can only retry notifications for your role or assigned areas';
  END IF;

  UPDATE public.wa_notification_queue
  SET
    status = 'pending',
    retry_count = 0,
    next_attempt_at = now(),
    last_error = NULL,
    processed_at = NULL,
    updated_at = now()
  WHERE id = p_queue_id;

  INSERT INTO public.wa_notification_logs (queue_id, endpoint, request_payload, response_status, response_body, success, error_message)
  VALUES (
    p_queue_id,
    'user/retry',
    jsonb_build_object('user_uid', auth.uid(), 'user_role', v_user_role, 'action', 'retry')::jsonb,
    NULL,
    NULL,
    TRUE,
    'User ' || v_user_role || ' triggered retry'
  );
END;
$$;

-- 4) Perca Take WhatsApp Batching Idempotency Table
CREATE TABLE IF NOT EXISTS public.wa_perca_take_batches (
  id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  batch_key TEXT NOT NULL UNIQUE,
  tailor_id UUID NOT NULL,
  staff_id UUID,
  date_entry DATE NOT NULL,
  tx_count INTEGER NOT NULL DEFAULT 0,
  total_weight NUMERIC NOT NULL DEFAULT 0,
  source_transaction_ids UUID[] NOT NULL DEFAULT '{}'::UUID[],
  status TEXT NOT NULL DEFAULT 'processing' CHECK (status IN ('processing', 'sent', 'failed')),
  notification_queue_ids BIGINT[] NOT NULL DEFAULT '{}'::BIGINT[],
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  processed_at TIMESTAMPTZ,
  last_error TEXT
);
COMMENT ON TABLE public.wa_perca_take_batches IS 'Guard idempotensi notifikasi WA grouped untuk pengambilan perca oleh penjahit.';
CREATE INDEX IF NOT EXISTS idx_wa_perca_take_batches_tailor_date ON public.wa_perca_take_batches (tailor_id, date_entry, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wa_perca_take_batches_status ON public.wa_perca_take_batches (status, created_at DESC);

-- 5) Queue Perca Take Batch Worker
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

-- 6) Reset and attach unified trigger
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

