-- ============================================================
-- MIGRATION: Admin RPCs for WA notification monitoring & manual retry
-- Date: 2026-04-15
--
-- Adds:
--   1. rpc_admin_get_wa_notifications  (read queue + latest log)
--   2. rpc_admin_retry_wa_notification (manual resend/retry with optional edit)
--
-- Notes:
--   - Uses SECURITY DEFINER and explicit admin check via profiles.role
--   - Keeps queue table restricted from authenticated clients directly
-- ============================================================

CREATE OR REPLACE FUNCTION public.rpc_admin_get_wa_notifications(
  p_status TEXT DEFAULT NULL,
  p_source_table TEXT DEFAULT NULL,
  p_limit INT DEFAULT 50,
  p_offset INT DEFAULT 0
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
  latest_response_status INTEGER,
  latest_response_body TEXT,
  latest_success BOOLEAN,
  latest_log_error_message TEXT,
  latest_log_created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role::text = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access denied. Admin only.';
  END IF;

  RETURN QUERY
  WITH latest_log AS (
    SELECT DISTINCT ON (l.queue_id)
      l.queue_id,
      l.response_status,
      l.response_body,
      l.success,
      l.error_message,
      l.created_at
    FROM public.wa_notification_logs l
    WHERE l.queue_id IS NOT NULL
    ORDER BY l.queue_id, l.created_at DESC
  )
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
    ll.response_status,
    ll.response_body,
    ll.success,
    ll.error_message,
    ll.created_at
  FROM public.wa_notification_queue q
  LEFT JOIN latest_log ll ON ll.queue_id = q.id
  WHERE (p_status IS NULL OR q.status = p_status)
    AND (p_source_table IS NULL OR q.source_table = p_source_table)
  ORDER BY q.created_at DESC
  LIMIT GREATEST(COALESCE(p_limit, 50), 1)
  OFFSET GREATEST(COALESCE(p_offset, 0), 0);
END;
$$;

CREATE OR REPLACE FUNCTION public.rpc_admin_retry_wa_notification(
  p_queue_id BIGINT,
  p_new_message TEXT DEFAULT NULL
)
RETURNS public.wa_notification_queue
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row public.wa_notification_queue%ROWTYPE;
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role::text = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access denied. Admin only.';
  END IF;

  UPDATE public.wa_notification_queue q
  SET
    message = COALESCE(NULLIF(btrim(p_new_message), ''), q.message),
    status = 'pending',
    retry_count = 0,
    next_attempt_at = now(),
    last_error = NULL,
    processed_at = NULL
  WHERE q.id = p_queue_id
    AND q.status IN ('failed', 'pending', 'processing')
  RETURNING q.* INTO v_row;

  IF v_row.id IS NULL THEN
    RAISE EXCEPTION 'Queue item % not found or not retryable.', p_queue_id;
  END IF;

  RETURN v_row;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.rpc_admin_get_wa_notifications(TEXT, TEXT, INT, INT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.rpc_admin_get_wa_notifications(TEXT, TEXT, INT, INT) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.rpc_admin_retry_wa_notification(BIGINT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.rpc_admin_retry_wa_notification(BIGINT, TEXT) TO authenticated;
