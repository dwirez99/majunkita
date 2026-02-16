-- Create percas_plans table for managing perca retrieval plans
CREATE TABLE IF NOT EXISTS "public"."percas_plans" (
    "id" "uuid" DEFAULT "gen_random_uuid"() PRIMARY KEY NOT NULL,
    "id_factory" "uuid" NOT NULL REFERENCES "public"."factories"("id") ON DELETE CASCADE,
    "planned_date" "date" NOT NULL,
    "status" character varying DEFAULT 'PENDING' NOT NULL CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
    "notes" "text",
    "created_by" "uuid" NOT NULL REFERENCES "public"."profiles"("id") ON DELETE SET NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."percas_plans" OWNER TO "postgres";

COMMENT ON TABLE "public"."percas_plans" IS 'Tabel untuk mengelola rencana pengambilan perca dari pabrik';

-- Create index untuk improve query performance
CREATE INDEX "idx_percas_plans_status" ON "public"."percas_plans"("status");
CREATE INDEX "idx_percas_plans_id_factory" ON "public"."percas_plans"("id_factory");
CREATE INDEX "idx_percas_plans_planned_date" ON "public"."percas_plans"("planned_date");
CREATE INDEX "idx_percas_plans_created_by" ON "public"."percas_plans"("created_by");

-- Enable RLS
ALTER TABLE "public"."percas_plans" FORCE ROW LEVEL SECURITY;

-- RLS Policies for percas_plans
-- 1. Admin dan Manager dapat melihat semua rencana
CREATE POLICY "Admin dan Manager dapat melihat semua percas_plans"
  ON "public"."percas_plans" FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM "public"."profiles"
      WHERE "id" = auth.uid() AND "role" IN ('admin', 'manager')
    )
  );

-- 2. Admin dapat membuat rencana baru
CREATE POLICY "Admin dapat membuat percas_plans"
  ON "public"."percas_plans" FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM "public"."profiles"
      WHERE "id" = auth.uid() AND "role" = 'admin'
    )
  );

-- 3. Manager dapat update status rencana
CREATE POLICY "Manager dapat update status percas_plans"
  ON "public"."percas_plans" FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM "public"."profiles"
      WHERE "id" = auth.uid() AND "role" = 'manager'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM "public"."profiles"
      WHERE "id" = auth.uid() AND "role" = 'manager'
    )
  );

-- 4. Admin dapat delete rencana
CREATE POLICY "Admin dapat delete percas_plans"
  ON "public"."percas_plans" FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM "public"."profiles"
      WHERE "id" = auth.uid() AND "role" = 'admin'
    )
  );
