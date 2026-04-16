-- ============================================================
-- MIGRATION: Clean up duplicate WA admin RPCs and fix search_path
-- Date: 2026-04-17
--
-- Context:
--   20260415183000 created rpc_admin_get_wa_notifications / rpc_admin_retry_wa_notification.
--   20260416090000 created rpc_get_wa_notifications / rpc_retry_wa_notification (newer names).
--   The Flutter app uses only the newer names; the admin_* variants are unused.
--
-- Changes:
--   1) Drop the unused rpc_admin_* functions from 20260415183000.
--   2) Add SET search_path = public to _check_is_admin() (security best practice
--      for SECURITY DEFINER functions).
-- ============================================================

-- 1) Drop unused legacy admin RPCs (Flutter uses rpc_get_wa_notifications instead)
DROP FUNCTION IF EXISTS public.rpc_admin_get_wa_notifications(TEXT, TEXT, INT, INT);
DROP FUNCTION IF EXISTS public.rpc_admin_retry_wa_notification(BIGINT, TEXT);

-- 2) Fix _check_is_admin: add SET search_path = public
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

COMMENT ON FUNCTION public._check_is_admin() IS
  'Internal helper: raises an exception if the current session user is not an admin. Used by SECURITY DEFINER RPCs.';
