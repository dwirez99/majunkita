-- Migration: Create tailors table with RLS policies
-- This table stores information about tailors (penjahit) who process textile waste

-- ============================================================================
-- 1. CREATE TAILORS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.tailors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nama_lengkap VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    no_telp VARCHAR(20) NOT NULL,
    alamat TEXT,
    spesialisasi VARCHAR(255), -- e.g., "Jahit Baju", "Tas", "Aksesoris"
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- 2. CREATE INDEX FOR BETTER QUERY PERFORMANCE
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_tailors_email ON public.tailors(email);
CREATE INDEX IF NOT EXISTS idx_tailors_nama_lengkap ON public.tailors(nama_lengkap);

-- ============================================================================
-- 3. ENABLE ROW LEVEL SECURITY
-- ============================================================================
ALTER TABLE public.tailors ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 4. CREATE RLS POLICIES
-- ============================================================================

-- Policy: Public can read all tailors (for general access)
-- If you want to restrict this, change TO public to TO authenticated
DROP POLICY IF EXISTS "Anyone can read tailors" ON public.tailors;
CREATE POLICY "Anyone can read tailors"
ON public.tailors
FOR SELECT
TO public
USING (true);

-- Policy: Authenticated users can insert tailors
DROP POLICY IF EXISTS "Authenticated users can insert tailors" ON public.tailors;
CREATE POLICY "Authenticated users can insert tailors"
ON public.tailors
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Policy: Authenticated users can update tailors
DROP POLICY IF EXISTS "Authenticated users can update tailors" ON public.tailors;
CREATE POLICY "Authenticated users can update tailors"
ON public.tailors
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Policy: Only admin and manager can delete tailors
DROP POLICY IF EXISTS "Admin and Manager can delete tailors" ON public.tailors;
CREATE POLICY "Admin and Manager can delete tailors"
ON public.tailors
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid()
        AND role IN ('admin', 'manager')
    )
);

-- ============================================================================
-- 5. CREATE TRIGGER FOR AUTOMATIC UPDATED_AT
-- ============================================================================
DROP TRIGGER IF EXISTS on_tailors_updated ON public.tailors;
CREATE TRIGGER on_tailors_updated
    BEFORE UPDATE ON public.tailors
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================================
-- 6. GRANT PERMISSIONS
-- ============================================================================
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.tailors TO authenticated;
GRANT ALL ON public.tailors TO service_role;
GRANT SELECT ON public.tailors TO anon;
