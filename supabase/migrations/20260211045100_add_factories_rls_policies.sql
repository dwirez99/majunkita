-- Add RLS policies for factories table
-- Only Admin can INSERT, UPDATE, DELETE
-- All authenticated users can SELECT (read-only for non-admin)

-- Drop existing policies if any
DROP POLICY IF EXISTS "Admin can insert factories" ON public.factories;
DROP POLICY IF EXISTS "Admin can update factories" ON public.factories;
DROP POLICY IF EXISTS "Admin can delete factories" ON public.factories;
DROP POLICY IF EXISTS "Everyone can view factories" ON public.factories;

-- SELECT policy: All authenticated users can view factories
CREATE POLICY "Everyone can view factories" 
ON public.factories 
FOR SELECT 
TO authenticated 
USING (true);

-- INSERT policy: Only Admin can insert factories
CREATE POLICY "Admin can insert factories" 
ON public.factories 
FOR INSERT 
TO authenticated 
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() 
    AND role = 'admin'
  )
);

-- UPDATE policy: Only Admin can update factories
CREATE POLICY "Admin can update factories" 
ON public.factories 
FOR UPDATE 
TO authenticated 
USING (
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() 
    AND role = 'admin'
  )
);

-- DELETE policy: Only Admin can delete factories
CREATE POLICY "Admin can delete factories" 
ON public.factories 
FOR DELETE 
TO authenticated 
USING (
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() 
    AND role = 'admin'
  )
);
