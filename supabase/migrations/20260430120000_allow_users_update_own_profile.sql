-- Allow authenticated users to update their own profile
-- This enables drivers, tailors, factories, and other non-admin users
-- to edit their own profile information without requiring admin/manager role.

-- Drop the policy if it exists (in case it was already created)
DROP POLICY IF EXISTS "Users can update their own profile" ON "public"."profiles";

CREATE POLICY "Users can update their own profile"
  ON "public"."profiles"
  AS permissive
  FOR UPDATE
  TO authenticated
  USING ((auth.uid() = id))
  WITH CHECK ((auth.uid() = id));
