-- ============================================================
-- MIGRATION: Expedition Partners
-- Date: 2026-03-05
--
-- Adds a dedicated expedition_partners table to store
-- shipping/logistics company data (e.g. JNE, TIKI, SiCepat).
--
-- Also adds id_expedition_partner column on expeditions table
-- so each expedition record can reference which logistics
-- company handled the shipment.
-- ============================================================

-- ============================================================
-- 1. Create expedition_partners table
-- ============================================================
CREATE TABLE IF NOT EXISTS "public"."expedition_partners" (
    "id"         uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    "name"       character varying                          NOT NULL,
    "no_telp"    character varying,
    "address"    character varying,
    "created_at" timestamp with time zone DEFAULT now()     NOT NULL,
    CONSTRAINT "expedition_partners_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "public"."expedition_partners" OWNER TO "postgres";

COMMENT ON TABLE "public"."expedition_partners"
  IS 'Tabel untuk menyimpan data mitra/perusahaan expedisi pengiriman barang (JNE, TIKI, SiCepat, dll).';

-- Enable Row Level Security
ALTER TABLE "public"."expedition_partners" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."expedition_partners" FORCE ROW LEVEL SECURITY;

-- ============================================================
-- 2. RLS Policies for expedition_partners
-- ============================================================

-- All authenticated internal staff can view
CREATE POLICY "Internal staff can view expedition partners"
  ON "public"."expedition_partners"
  AS PERMISSIVE
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role::text = ANY (
          ARRAY['admin', 'manager', 'driver']::text[]
        )
    )
  );

-- Only admin/manager can insert
CREATE POLICY "Admin and Manager can create expedition partners"
  ON "public"."expedition_partners"
  AS PERMISSIVE
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role::text = ANY (
          ARRAY['admin', 'manager']::text[]
        )
    )
  );

-- Only admin/manager can update
CREATE POLICY "Admin and Manager can update expedition partners"
  ON "public"."expedition_partners"
  AS PERMISSIVE
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role::text = ANY (
          ARRAY['admin', 'manager']::text[]
        )
    )
  );

-- Only admin/manager can delete
CREATE POLICY "Admin and Manager can delete expedition partners"
  ON "public"."expedition_partners"
  AS PERMISSIVE
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role::text = ANY (
          ARRAY['admin', 'manager']::text[]
        )
    )
  );

-- ============================================================
-- 3. Add id_expedition_partner column to expeditions table
--    (nullable FK — existing rows won't break)
-- ============================================================
ALTER TABLE "public"."expeditions"
  ADD COLUMN IF NOT EXISTS "id_expedition_partner" uuid
    REFERENCES "public"."expedition_partners"("id") ON DELETE SET NULL;

COMMENT ON COLUMN "public"."expeditions"."id_expedition_partner"
  IS 'FK ke expedition_partners: mitra/perusahaan expedisi yang menangani pengiriman ini.';
