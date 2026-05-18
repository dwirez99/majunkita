-- ============================================================
-- MIGRATION: Fix Infinite Recursion in Profiles RLS Policies
-- Date: 2026-05-18
--
-- Problem:
--   The INSERT, UPDATE, and DELETE policies on the 'profiles' table
--   used EXISTS subqueries that re-queried 'profiles' to check the
--   current user's role. This causes infinite recursion (error 42P17)
--   because evaluating the policy triggers the policy again.
--
-- Fix:
--   Replace self-referencing subqueries with auth.jwt() ->> 'app_metadata'
--   or a SECURITY DEFINER helper function that bypasses RLS to check
--   the current user's role safely.
-- ============================================================

-- Step 1: Create a SECURITY DEFINER helper function to get the current
--         user's role without triggering RLS on the profiles table.
CREATE OR REPLACE FUNCTION public.get_current_user_role()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role::TEXT FROM public.profiles WHERE id = auth.uid() LIMIT 1;
$$;

REVOKE EXECUTE ON FUNCTION public.get_current_user_role() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_current_user_role() TO authenticated;

-- Step 2: Drop all conflicting policies on profiles
DROP POLICY IF EXISTS "Admin and Manager can delete profiles" ON "public"."profiles";
DROP POLICY IF EXISTS "Admin and Manager can insert profiles" ON "public"."profiles";
DROP POLICY IF EXISTS "Admin and Manager can update profiles" ON "public"."profiles";
DROP POLICY IF EXISTS "Public profiles are viewable by everyone"  ON "public"."profiles";
DROP POLICY IF EXISTS "user_bisa_lihat_profilnya_sendiri"          ON "public"."profiles";
DROP POLICY IF EXISTS "Users can update their own profile"         ON "public"."profiles";

-- Step 3: Recreate SELECT policy — one clear, non-recursive policy.
--   All authenticated users can read all profiles (needed for admin lists, etc.)
CREATE POLICY "profiles_select_authenticated"
  ON "public"."profiles"
  FOR SELECT
  TO authenticated
  USING (true);

-- Step 4: INSERT — only admin or manager (uses helper, no recursion)
CREATE POLICY "profiles_insert_admin_manager"
  ON "public"."profiles"
  FOR INSERT
  TO authenticated
  WITH CHECK (
    public.get_current_user_role() IN ('admin', 'manager')
  );

-- Step 5: UPDATE — admin/manager can update anyone; user can update own profile
CREATE POLICY "profiles_update_admin_manager"
  ON "public"."profiles"
  FOR UPDATE
  TO authenticated
  USING (
    public.get_current_user_role() IN ('admin', 'manager')
    OR auth.uid() = id
  )
  WITH CHECK (
    public.get_current_user_role() IN ('admin', 'manager')
    OR auth.uid() = id
  );

-- Step 6: DELETE — only admin or manager
CREATE POLICY "profiles_delete_admin_manager"
  ON "public"."profiles"
  FOR DELETE
  TO authenticated
  USING (
    public.get_current_user_role() IN ('admin', 'manager')
  );
