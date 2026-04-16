-- ============================================================
-- MIGRATION: Admin RPCs for WA Notifications
-- Date: 2026-04-16
--
-- Adds two RPCs for the admin UI:
-- 1) rpc_get_wa_notifications(p_limit, p_offset, p_status)
--    - Returns wa_notification_queue rows with the most recent log joined
--    - Only callable by authenticated users who are admins (checks profiles.role)
-- 2) rpc_retry_wa_notification(p_queue_id)
--    - Resets a queue row to pending and clears retry metadata so it will be retried
--    - Only callable by authenticated admins
-- ============================================================

CREATE OR REPLACE FUNCTION public._check_is_admin()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
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

-- RPC: list notifications with latest attempt info
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
AS $$
BEGIN
  PERFORM public._check_is_admin();

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
    SELECT response_status, success, error_message, response_body, created_at
    FROM public.wa_notification_logs
    WHERE queue_id = q.id
    ORDER BY created_at DESC
    LIMIT 1
  ) l ON true
  WHERE (p_status IS NULL OR q.status = p_status)
  ORDER BY q.created_at DESC
  LIMIT GREATEST(COALESCE(p_limit,50), 1)
  OFFSET GREATEST(COALESCE(p_offset,0), 0);
END;
$$;

-- RPC: retry a specific notification (admin only)
CREATE OR REPLACE FUNCTION public.rpc_retry_wa_notification(p_queue_id BIGINT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_queue RECORD;
BEGIN
  PERFORM public._check_is_admin();

  SELECT * INTO v_queue FROM public.wa_notification_queue WHERE id = p_queue_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Queue entry not found: %', p_queue_id;
  END IF;

  -- Reset retry metadata and set to pending
  UPDATE public.wa_notification_queue
  SET
    status = 'pending',
    retry_count = 0,
    next_attempt_at = now(),
    last_error = NULL,
    processed_at = NULL,
    updated_at = now()
  WHERE id = p_queue_id;

  -- Log admin retry action
  INSERT INTO public.wa_notification_logs (queue_id, endpoint, request_payload, response_status, response_body, success, error_message)
  VALUES (
    p_queue_id,
    'admin/retry',
    jsonb_build_object('admin_uid', auth.uid(), 'action', 'retry')::jsonb,
    NULL,
    NULL,
    TRUE,
    'Admin triggered retry'
  );
END;
$$;

-- Grant execute to authenticated so admin users can call these RPCs (function itself enforces admin role)
GRANT EXECUTE ON FUNCTION public.rpc_get_wa_notifications(INTEGER, INTEGER, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_retry_wa_notification(BIGINT) TO authenticated;

COMMENT ON FUNCTION public.rpc_get_wa_notifications(INTEGER, INTEGER, TEXT) IS 'Returns list of wa_notification_queue rows with latest log; only callable by admin users (checks profiles.role)';
COMMENT ON FUNCTION public.rpc_retry_wa_notification(BIGINT) IS 'Reset a wa_notification_queue row to pending for manual retry; only callable by admin users (checks profiles.role)';
