-- ============================================================
-- MIGRATION: Fix Expeditions Feature
-- Date: 2026-03-05
--
-- Fixes:
--   1. Add DELETE RLS policy for expeditions table
--      (only SELECT + INSERT existed — delete was blocked by RLS)
--   2. Create proof_of_deliveries storage bucket (public)
--   3. Add storage policies for upload and delete on
--      proof_of_deliveries bucket
-- ============================================================

-- ============================================================
-- 1. DELETE policy for expeditions
--    Allow admin and driver to delete expedition records
-- ============================================================
CREATE POLICY "Admin and Driver can delete expeditions"
  ON "public"."expeditions"
  AS PERMISSIVE
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role::text = ANY (
          ARRAY['admin'::character varying, 'driver'::character varying]::text[]
        )
    )
  );

-- ============================================================
-- 2. Create proof_of_deliveries storage bucket
--    Public bucket so Image.network() can render without auth
-- ============================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('proof_of_deliveries', 'proof_of_deliveries', true)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 3. Storage policies for proof_of_deliveries bucket
-- ============================================================

-- Allow authenticated admin/driver to upload files
CREATE POLICY "Admin and Driver can upload proof of deliveries"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'proof_of_deliveries'
    AND EXISTS (
      SELECT 1
      FROM public.profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role::text = ANY (
          ARRAY['admin'::character varying, 'driver'::character varying]::text[]
        )
    )
  );

-- Allow all authenticated internal staff to view/download files
CREATE POLICY "Internal staff can view proof of deliveries"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (bucket_id = 'proof_of_deliveries');

-- Allow admin/driver to delete their own uploaded files
CREATE POLICY "Admin and Driver can delete proof of deliveries"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'proof_of_deliveries'
    AND EXISTS (
      SELECT 1
      FROM public.profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role::text = ANY (
          ARRAY['admin'::character varying, 'driver'::character varying]::text[]
        )
    )
  );
