-- Add RLS policies for tailors table
-- This fixes the "row-level security policy" error when creating/reading tailors

-- Policy: Allow authenticated users to SELECT all tailors
CREATE POLICY "Authenticated users can view all tailors"
ON "public"."tailors"
FOR SELECT
TO authenticated
USING (true);

-- Policy: Allow authenticated users to INSERT tailors
CREATE POLICY "Authenticated users can create tailors"
ON "public"."tailors"
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Policy: Allow authenticated users to UPDATE tailors
CREATE POLICY "Authenticated users can update tailors"
ON "public"."tailors"
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Policy: Allow authenticated users to DELETE tailors
CREATE POLICY "Authenticated users can delete tailors"
ON "public"."tailors"
FOR DELETE
TO authenticated
USING (true);
