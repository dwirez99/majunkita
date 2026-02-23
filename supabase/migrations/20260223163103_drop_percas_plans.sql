-- Remove foreign key and column id_plan from percas_stock (depends on percas_plans)
ALTER TABLE "public"."percas_stock" DROP CONSTRAINT IF EXISTS "percas_stock_id_plan_fkey";
ALTER TABLE "public"."percas_stock" DROP COLUMN IF EXISTS "id_plan";

-- Drop the percas_plans table and all its dependents (policies, triggers, constraints)
DROP TABLE IF EXISTS "public"."percas_plans" CASCADE;