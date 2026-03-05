-- ============================================================
-- MIGRATION: Expedition Stock Check
-- Date: 2026-03-05
--
-- Adds:
--   1. RPC get_majun_available_stock()
--      Returns effective warehouse stock:
--        SUM(majun_transactions.weight_majun) - SUM(expeditions.total_weight)
--      Called by Flutter before the confirm dialog (UI-level guard).
--
--   2. Trigger function check_and_reserve_expedition_stock()
--      BEFORE INSERT on expeditions.
--      Recalculates available stock and raises an exception if
--      the new expedition's total_weight exceeds what is available.
--      This is the hard safety net — runs even if the UI check is bypassed.
-- ============================================================

-- ============================================================
-- 1. RPC: get_majun_available_stock
--    Returns: NUMERIC — kg available for dispatch
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_majun_available_stock()
RETURNS numeric
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT
    COALESCE(
      (SELECT SUM(weight_majun) FROM public.majun_transactions),
      0
    )
    -
    COALESCE(
      (SELECT SUM(total_weight) FROM public.expeditions),
      0
    );
$$;

REVOKE EXECUTE ON FUNCTION public.get_majun_available_stock() FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.get_majun_available_stock() TO authenticated;

COMMENT ON FUNCTION public.get_majun_available_stock() IS
  'Returns effective majun warehouse stock in kg: SUM(majun_transactions.weight_majun) - SUM(expeditions.total_weight).';

-- ============================================================
-- 2. TRIGGER FUNCTION: check_and_reserve_expedition_stock
--    Runs BEFORE INSERT on expeditions.
--    Raises an exception if total_weight > available stock.
-- ============================================================
CREATE OR REPLACE FUNCTION public.check_and_reserve_expedition_stock()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_total_in   NUMERIC;
  v_total_out  NUMERIC;
  v_available  NUMERIC;
BEGIN
  -- Total majun received from all tailors
  SELECT COALESCE(SUM(weight_majun), 0)
    INTO v_total_in
    FROM public.majun_transactions;

  -- Total already dispatched via past expeditions
  -- Exclude the row being inserted (it doesn't exist yet in BEFORE INSERT)
  SELECT COALESCE(SUM(total_weight), 0)
    INTO v_total_out
    FROM public.expeditions;

  v_available := v_total_in - v_total_out;

  IF NEW.total_weight > v_available THEN
    RAISE EXCEPTION
      'Stok majun tidak mencukupi. Tersedia: % kg, dibutuhkan: % kg. Kurangi jumlah karung atau tunggu setoran masuk.',
      v_available,
      NEW.total_weight;
  END IF;

  -- Stock is sufficient — allow the INSERT to proceed
  RETURN NEW;
END;
$$;

-- ============================================================
-- 3. Attach trigger to expeditions table
-- ============================================================
DROP TRIGGER IF EXISTS trg_check_expedition_stock ON public.expeditions;

CREATE TRIGGER trg_check_expedition_stock
  BEFORE INSERT ON public.expeditions
  FOR EACH ROW
  EXECUTE FUNCTION public.check_and_reserve_expedition_stock();

COMMENT ON FUNCTION public.check_and_reserve_expedition_stock() IS
  'BEFORE INSERT trigger on expeditions. Validates warehouse majun stock is sufficient before allowing the insert.';
