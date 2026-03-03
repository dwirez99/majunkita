-- ============================================================
-- MIGRATION: Security & Database Hardening
-- Date: 2026-03-03
--
-- Fixes:
--   1. REVOKE ALL FROM anon on financial tables
--   2. CHECK (total_stock >= 0) on tailors
--   3. Index on majun_transactions.id_tailor FK
--   4. Server-side RPC for monthly majun stats (GROUP BY)
--   5. Paginated rpc_get_majun_history / rpc_get_limbah_history
-- ============================================================

-- ============================================================
-- 1. REVOKE anon grants on financial tables
--    TODO: Decide whether app_settings needs anon SELECT
-- ============================================================
REVOKE ALL ON TABLE public.majun_transactions FROM anon;
REVOKE ALL ON TABLE public.limbah_transactions FROM anon;
REVOKE ALL ON TABLE public.salary_withdrawals FROM anon;
REVOKE ALL ON TABLE public.app_settings FROM anon;

-- Grant SELECT on app_settings to authenticated (price lookup)
-- anon gets nothing for now — revisit if unauthenticated reads are needed
GRANT SELECT ON TABLE public.app_settings TO authenticated;

-- ============================================================
-- 2. CHECK total_stock >= 0 on tailors
-- ============================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'chk_total_stock_non_negative'
      AND conrelid = 'public.tailors'::regclass
  ) THEN
    ALTER TABLE public.tailors
      ADD CONSTRAINT chk_total_stock_non_negative CHECK (total_stock >= 0);
  END IF;
END $$;

-- ============================================================
-- 3. Index on majun_transactions.id_tailor (FK not auto-indexed)
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_majun_transactions_id_tailor
  ON public.majun_transactions(id_tailor);

-- Also add index on limbah_transactions.id_tailor for consistency
CREATE INDEX IF NOT EXISTS idx_limbah_transactions_id_tailor
  ON public.limbah_transactions(id_tailor);

-- ============================================================
-- 4. Server-side RPC: Monthly majun stats (replaces client-side GROUP BY)
-- ============================================================
CREATE OR REPLACE FUNCTION public.rpc_get_monthly_majun_stats()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::jsonb) INTO v_result
  FROM (
    SELECT
      TO_CHAR(DATE_TRUNC('month', date_entry), 'YYYY-MM') AS month_key,
      SUM(weight_majun)::FLOAT8 AS total_weight
    FROM public.majun_transactions
    GROUP BY DATE_TRUNC('month', date_entry)
    ORDER BY DATE_TRUNC('month', date_entry) ASC
  ) t;

  RETURN v_result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.rpc_get_monthly_majun_stats() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.rpc_get_monthly_majun_stats() TO authenticated;

-- ============================================================
-- 5. Paginated history RPCs
--    Drop old no-arg versions, recreate with p_limit/p_offset
-- ============================================================

-- 5a. Majun history (paginated)
DROP FUNCTION IF EXISTS public.rpc_get_majun_history();

CREATE OR REPLACE FUNCTION public.rpc_get_majun_history(
  p_limit INT DEFAULT 50,
  p_offset INT DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::jsonb) INTO v_result
  FROM (
    SELECT
      mt.id,
      mt.id_tailor,
      tl.name AS tailor_name,
      mt.date_entry,
      mt.weight_majun,
      mt.earned_wage,
      mt.staff_id,
      mt.delivery_proof,
      mt.created_at
    FROM public.majun_transactions mt
    LEFT JOIN public.tailors tl ON tl.id = mt.id_tailor
    ORDER BY mt.created_at DESC
    LIMIT p_limit
    OFFSET p_offset
  ) t;

  RETURN v_result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.rpc_get_majun_history(INT, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.rpc_get_majun_history(INT, INT) TO authenticated;

-- 5b. Limbah history (paginated)
DROP FUNCTION IF EXISTS public.rpc_get_limbah_history();

CREATE OR REPLACE FUNCTION public.rpc_get_limbah_history(
  p_limit INT DEFAULT 50,
  p_offset INT DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::jsonb) INTO v_result
  FROM (
    SELECT
      lt.id,
      lt.id_tailor,
      tl.name AS tailor_name,
      lt.date_entry,
      lt.weight_limbah,
      lt.staff_id,
      lt.delivery_proof,
      lt.created_at
    FROM public.limbah_transactions lt
    LEFT JOIN public.tailors tl ON tl.id = lt.id_tailor
    ORDER BY lt.created_at DESC
    LIMIT p_limit
    OFFSET p_offset
  ) t;

  RETURN v_result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.rpc_get_limbah_history(INT, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.rpc_get_limbah_history(INT, INT) TO authenticated;
