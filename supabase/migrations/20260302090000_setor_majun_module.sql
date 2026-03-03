-- ============================================================
-- MIGRATION: Modul Setor Majun & Limbah (Revisi Skema Pragmatis)
-- Date: 2026-03-03
--
-- Aliran Transaksi:
--   1. Penjahit Ambil Perca → INSERT perca_transactions → Trigger MENAMBAH total_stock
--   2. Penjahit Setor Majun → INSERT majun_transactions → Trigger MENGURANGI total_stock & MENAMBAH balance
--   3. Penjahit Setor Limbah → INSERT limbah_transactions → Trigger MENGURANGI total_stock (tanpa upah)
-- ============================================================

-- ============================================================
-- 1. TABEL app_settings (harga standar per kg)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.app_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  description TEXT,
  updated_at TIMESTAMPTZ DEFAULT now(),
  updated_by UUID REFERENCES auth.users(id)
);

ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated can read settings"
  ON public.app_settings FOR SELECT TO authenticated USING (true);

CREATE POLICY "Admin Manager can update settings"
  ON public.app_settings FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid()
    AND (profiles.role)::text = ANY (ARRAY['admin', 'manager']::text[])
  ));

CREATE POLICY "Admin Manager can insert settings"
  ON public.app_settings FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid()
    AND (profiles.role)::text = ANY (ARRAY['admin', 'manager']::text[])
  ));

INSERT INTO public.app_settings (key, value, description)
VALUES ('majun_price_per_kg', '3000', 'Harga standar majun per kilogram (Rupiah)')
ON CONFLICT (key) DO NOTHING;

GRANT ALL ON TABLE public.app_settings TO anon;
GRANT ALL ON TABLE public.app_settings TO authenticated;
GRANT ALL ON TABLE public.app_settings TO service_role;

-- ============================================================
-- 2. EXTEND tabel tailors (tambah total_stock & balance)
-- ============================================================
ALTER TABLE public.tailors
  ADD COLUMN IF NOT EXISTS total_stock FLOAT8 DEFAULT 0,
  ADD COLUMN IF NOT EXISTS balance NUMERIC DEFAULT 0;

-- ============================================================
-- 3. CREATE tabel majun_transactions (SETOR MAJUN SAJA)
--    Hanya mencatat berat lap majun yang disetor penjahit.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.majun_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_tailor UUID NOT NULL REFERENCES public.tailors(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  date_entry DATE NOT NULL DEFAULT CURRENT_DATE,
  weight_majun NUMERIC(10,2) NOT NULL CHECK (weight_majun > 0),
  earned_wage NUMERIC(10,2) DEFAULT 0,
  staff_id UUID REFERENCES public.profiles(id),
  delivery_proof TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.majun_transactions ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE public.majun_transactions IS 'Pencatatan setor lap majun dari penjahit. Trigger auto menghitung upah & update stok.';

CREATE POLICY "Admin Full Access Majun Transactions"
  ON public.majun_transactions FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid() AND (profiles.role)::text = 'admin'
  ));

CREATE POLICY "Manager Monitor Majun Transactions"
  ON public.majun_transactions FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid() AND (profiles.role)::text = 'manager'
  ));

GRANT ALL ON TABLE public.majun_transactions TO anon;
GRANT ALL ON TABLE public.majun_transactions TO authenticated;
GRANT ALL ON TABLE public.majun_transactions TO service_role;

-- ============================================================
-- 4. CREATE tabel limbah_transactions (SETOR LIMBAH SAJA)
--    Mencatat limbah yang dikembalikan penjahit.
--    TIDAK menambah upah, hanya mengurangi total_stock.
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
COMMENT ON TABLE public.limbah_transactions IS 'Pencatatan setor limbah dari penjahit. Trigger auto mengurangi stok tanpa menambah upah.';

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
-- 5. CREATE tabel salary_withdrawals (Penarikan Upah)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.salary_withdrawals (
  id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  id_tailor UUID NOT NULL REFERENCES public.tailors(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  amount NUMERIC NOT NULL,
  date_entry DATE NOT NULL DEFAULT CURRENT_DATE
);

ALTER TABLE public.salary_withdrawals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin Full Access Salary Withdrawals"
  ON public.salary_withdrawals FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid() AND (profiles.role)::text = 'admin'
  ));

CREATE POLICY "Manager Monitor Salary Withdrawals"
  ON public.salary_withdrawals FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid() AND (profiles.role)::text = 'manager'
  ));

GRANT ALL ON TABLE public.salary_withdrawals TO anon;
GRANT ALL ON TABLE public.salary_withdrawals TO authenticated;
GRANT ALL ON TABLE public.salary_withdrawals TO service_role;

-- ============================================================
-- 6. TRIGGER: perca_transactions → MENAMBAH total_stock penjahit
--    Saat penjahit ambil perca, stok yang dia pegang bertambah.
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
-- 7. TRIGGER: majun_transactions
--    BEFORE INSERT → Hitung earned_wage otomatis dari app_settings
--    AFTER INSERT  → Kurangi total_stock & Tambah balance penjahit
-- ============================================================

-- 7a. BEFORE INSERT: Auto-calculate earned_wage
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

  -- Auto-hitung upah
  NEW.earned_wage := NEW.weight_majun * v_price;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_majun_calc_wage ON public.majun_transactions;
CREATE TRIGGER trg_majun_calc_wage
  BEFORE INSERT ON public.majun_transactions
  FOR EACH ROW
  EXECUTE FUNCTION fn_majun_before_insert();

-- 7b. AFTER INSERT: Update tailors stock & balance
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
-- 8. TRIGGER: limbah_transactions → MENGURANGI total_stock saja
--    Saat penjahit setor limbah, stoknya berkurang tanpa menambah upah.
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
-- 9. RPC: rpc_get_majun_history (Helper untuk history + nama penjahit)
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
-- 10. RPC: rpc_get_limbah_history (Helper untuk history + nama penjahit)
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
