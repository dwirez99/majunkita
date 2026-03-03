-- Fix: Add missing created_at column to majun_transactions
-- The original migration didn't include it, but RPCs reference it.

-- Add created_at to majun_transactions
ALTER TABLE public.majun_transactions
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now();

-- Recreate RPC with fixed column references
CREATE OR REPLACE FUNCTION public.rpc_get_majun_history()
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
  ) t;

  RETURN v_result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.rpc_get_majun_history() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.rpc_get_majun_history() TO authenticated;
