-- 1. Hapus constraint lama yang membatasi status
ALTER TABLE "public"."percas_plans" 
DROP CONSTRAINT IF EXISTS "percas_plans_status_check";

-- 2. Tambahkan constraint baru dengan 'COMPLETED' di dalamnya
ALTER TABLE "public"."percas_plans"
ADD CONSTRAINT "percas_plans_status_check" 
CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'COMPLETED'));