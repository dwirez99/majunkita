-- ============================================================
-- MIGRATION: Revisi Skema Majun & Tambah Limbah
-- Date: 2026-03-03
--
-- Perubahan dari skema sebelumnya (20260302090000):
--   1. majun_transactions: rename weight → weight_majun, DROP waste
--   2. CREATE limbah_transactions (tabel baru)
--   3. DROP old RPCs (rpc_setor_majun), ganti dengan triggers
--   4. CREATE triggers untuk otomasi stock & balance
--   5. CREATE rpc_get_limbah_history
-- ============================================================

-- ============================================================
-- 1. ALTER majun_transactions: rename weight → weight_majun, DROP waste
-- ============================================================

-- Rename 'weight' to 'weight_majun'
ALTER TABLE public.majun_transactions
  RENAME COLUMN weight TO weight_majun;

-- Drop 'waste' column (limbah sekarang di tabel terpisah)
ALTER TABLE public.majun_transactions
  DROP COLUMN IF EXISTS waste;

-- Add check constraint for weight_majun
ALTER TABLE public.majun_transactions
  ADD CONSTRAINT chk_weight_majun_positive CHECK (weight_majun > 0);

-- ============================================================
-- 2. CREATE limbah_transactions (Setor Limbah - tabel baru)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.limbah_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_tailor UUID NOT NULL REFERENCES public.tailors(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  date_entry DATE NOT NULL DEFAULT CURRENT_DATE,
  weight_limbah NUMERIC(10,2) NOT NULL CHECK (weight_limbah > 0),
  staff_id UUID REFERENCES public.profiles(id),
  delivery_proof TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.limbah_transactions ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE public.limbah_transactions IS 'Pencatatan setor limbah dari penjahit. Trigger mengurangi stok tanpa menambah upah.';

CREATE POLICY "Admin Full Access Limbah Transactions"
  ON public.limbah_transactions FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid() AND (profiles.role)::text = 'admin'
  ));

CREATE POLICY "Manager Monitor Limbah Transactions"
  ON public.limbah_transactions FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid() AND (profiles.role)::text = 'manager'
  ));

GRANT ALL ON TABLE public.limbah_transactions TO anon;
GRANT ALL ON TABLE public.limbah_transactions TO authenticated;
GRANT ALL ON TABLE public.limbah_transactions TO service_role;

-- ============================================================
-- 3. DROP old RPC rpc_setor_majun (replaced by triggers)
-- ============================================================
DROP FUNCTION IF EXISTS public.rpc_setor_majun(UUID, NUMERIC, TEXT, UUID);
DROP FUNCTION IF EXISTS public.rpc_setor_majun(UUID, NUMERIC, TEXT, UUID, NUMERIC);

-- ============================================================
-- 4. TRIGGER: perca_transactions → MENAMBAH total_stock penjahit
-- ============================================================
CREATE OR REPLACE FUNCTION fn_perca_after_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.tailors
  SET total_stock = COALESCE(total_stock, 0) + NEW.weight
  WHERE id = NEW.id_tailors;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_perca_add_stock ON public.perca_transactions;
CREATE TRIGGER trg_perca_add_stock
  AFTER INSERT ON public.perca_transactions
  FOR EACH ROW
  EXECUTE FUNCTION fn_perca_after_insert();

-- ============================================================
-- 5. TRIGGER: majun_transactions
--    BEFORE INSERT → Auto-calculate earned_wage
--    AFTER INSERT  → Update tailors stock & balance
-- ============================================================

-- 5a. BEFORE INSERT: Auto-hitung earned_wage
CREATE OR REPLACE FUNCTION fn_majun_before_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_price NUMERIC;
BEGIN
  SELECT value::NUMERIC INTO v_price
  FROM public.app_settings
  WHERE key = 'majun_price_per_kg'
  LIMIT 1;

  IF v_price IS NULL THEN
    RAISE EXCEPTION 'Harga standar majun belum diset di app_settings (key: majun_price_per_kg)';
  END IF;

  NEW.earned_wage := NEW.weight_majun * v_price;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_majun_calc_wage ON public.majun_transactions;
CREATE TRIGGER trg_majun_calc_wage
  BEFORE INSERT ON public.majun_transactions
  FOR EACH ROW
  EXECUTE FUNCTION fn_majun_before_insert();

-- 5b. AFTER INSERT: Update tailors
CREATE OR REPLACE FUNCTION fn_majun_after_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.tailors
  SET total_stock = COALESCE(total_stock, 0) - NEW.weight_majun,
      balance = COALESCE(balance, 0) + NEW.earned_wage
  WHERE id = NEW.id_tailor;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_majun_update_tailor ON public.majun_transactions;
CREATE TRIGGER trg_majun_update_tailor
  AFTER INSERT ON public.majun_transactions
  FOR EACH ROW
  EXECUTE FUNCTION fn_majun_after_insert();

-- ============================================================
-- 6. TRIGGER: limbah_transactions → MENGURANGI total_stock saja
-- ============================================================
CREATE OR REPLACE FUNCTION fn_limbah_after_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.tailors
  SET total_stock = COALESCE(total_stock, 0) - NEW.weight_limbah
  WHERE id = NEW.id_tailor;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_limbah_reduce_stock ON public.limbah_transactions;
CREATE TRIGGER trg_limbah_reduce_stock
  AFTER INSERT ON public.limbah_transactions
  FOR EACH ROW
  EXECUTE FUNCTION fn_limbah_after_insert();

-- ============================================================
-- 7. UPDATE rpc_get_majun_history (use weight_majun instead of weight)
-- ============================================================
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

-- ============================================================
-- 8. CREATE rpc_get_limbah_history
-- ============================================================
CREATE OR REPLACE FUNCTION public.rpc_get_limbah_history()
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
  ) t;

  RETURN v_result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.rpc_get_limbah_history() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.rpc_get_limbah_history() TO authenticated;
