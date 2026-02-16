-- Allow Admin to update percas_plans status to COMPLETED when adding perca stock
-- This is needed because only Admins can add perca stock, but the old policy
-- only allowed Managers to update percas_plans

-- Drop the old policy that only allows Manager
DROP POLICY IF EXISTS "Manager dapat update status percas_plans" ON "public"."percas_plans";

-- Create new policy that allows both Admin and Manager to update
CREATE POLICY "Admin dan Manager dapat update percas_plans"
  ON "public"."percas_plans" FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM "public"."profiles"
      WHERE "id" = auth.uid() AND "role" IN ('admin', 'manager')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM "public"."profiles"
      WHERE "id" = auth.uid() AND "role" IN ('admin', 'manager')
    )
  );
