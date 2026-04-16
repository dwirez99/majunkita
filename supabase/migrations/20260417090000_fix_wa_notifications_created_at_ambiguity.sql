-- ============================================================
-- MIGRATION: Fix ambiguous created_at reference in WA admin RPC
-- Date: 2026-04-17
--
-- Root cause:
-- In PL/pgSQL RETURN TABLE functions, output column names behave like
-- variables in function scope. Because this function returns a column
-- named "created_at", unqualified ORDER BY "created_at" inside the
-- lateral subquery becomes ambiguous (can refer to table column or
-- output variable).
--
-- Fix:
-- Qualify the ORDER BY column with table alias in lateral subquery:
--   ORDER BY wl.created_at DESC
-- ============================================================

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
    SELECT
      wl.response_status,
      wl.success,
      wl.error_message,
      wl.response_body,
      wl.created_at
    FROM public.wa_notification_logs wl
    WHERE wl.queue_id = q.id
    ORDER BY wl.created_at DESC
    LIMIT 1
  ) l ON true
  WHERE (p_status IS NULL OR q.status = p_status)
  ORDER BY q.created_at DESC
  LIMIT GREATEST(COALESCE(p_limit, 50), 1)
  OFFSET GREATEST(COALESCE(p_offset, 0), 0);
END;
$$;

-- Keep grants explicit for safety/documentation
GRANT EXECUTE ON FUNCTION public.rpc_get_wa_notifications(INTEGER, INTEGER, TEXT) TO authenticated;

COMMENT ON FUNCTION public.rpc_get_wa_notifications(INTEGER, INTEGER, TEXT)
IS 'Returns list of wa_notification_queue rows with latest log; fixed ambiguous created_at reference in lateral ORDER BY; only callable by admin users (checks profiles.role)';
