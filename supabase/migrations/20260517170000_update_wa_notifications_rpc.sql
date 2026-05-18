CREATE OR REPLACE FUNCTION public.rpc_get_wa_notifications(
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0,
  p_status TEXT DEFAULT NULL,
  p_start_date DATE DEFAULT NULL,
  p_end_date DATE DEFAULT NULL,
  p_event_type TEXT DEFAULT NULL
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
    AND (p_event_type IS NULL OR q.event_type = p_event_type)
    AND (p_start_date IS NULL OR q.created_at >= p_start_date::TIMESTAMPTZ)
    AND (p_end_date IS NULL OR q.created_at < (p_end_date + INTERVAL '1 day')::TIMESTAMPTZ)
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
