-- ============================================================
-- RPC: get_tailor_efficiency_stats
-- Menghitung statistik efisiensi penjahit di sisi server.
--
-- Mengembalikan:
--   sisa_perca          NUMERIC  -- total_stock saat ini (saldo mengendap)
--   total_perca_diambil NUMERIC  -- SUM berat dari perca_transactions
--   total_majun_disetor NUMERIC  -- SUM berat dari majun_transactions
--   total_limbah_disetor NUMERIC -- SUM berat dari limbah_transactions
--   reff                NUMERIC  -- total_majun / total_perca (0 jika belum ada data)
--   prediksi_majun      NUMERIC  -- sisa_perca × reff
-- ============================================================

CREATE OR REPLACE FUNCTION get_tailor_efficiency_stats(p_tailor_id UUID)
RETURNS TABLE (
    sisa_perca           NUMERIC,
    total_perca_diambil  NUMERIC,
    total_majun_disetor  NUMERIC,
    total_limbah_disetor NUMERIC,
    reff                 NUMERIC,
    prediksi_majun       NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_sisa_perca           NUMERIC := 0;
    v_total_perca_diambil  NUMERIC := 0;
    v_total_majun_disetor  NUMERIC := 0;
    v_total_limbah_disetor NUMERIC := 0;
    v_reff                 NUMERIC := 0;
    v_prediksi_majun       NUMERIC := 0;
BEGIN
    -- 1. Sisa perca saat ini (total_stock dari tailors)
    SELECT COALESCE(t.total_stock, 0)
      INTO v_sisa_perca
      FROM tailors t
     WHERE t.id = p_tailor_id;

    -- 2. Total perca yang pernah diambil dari gudang
    SELECT COALESCE(SUM(pt.weight), 0)
      INTO v_total_perca_diambil
      FROM perca_transactions pt
     WHERE pt.id_tailors = p_tailor_id;

    -- 3. Total majun yang pernah disetor
    SELECT COALESCE(SUM(mt.weight_majun), 0)
      INTO v_total_majun_disetor
      FROM majun_transactions mt
     WHERE mt.id_tailor = p_tailor_id;

    -- 4. Total limbah yang pernah disetor
    SELECT COALESCE(SUM(lt.weight_limbah), 0)
      INTO v_total_limbah_disetor
      FROM limbah_transactions lt
     WHERE lt.id_tailor = p_tailor_id;

    -- 5. Reff = majun / perca  (0 jika belum ada data)
    IF v_total_perca_diambil > 0 THEN
        v_reff := v_total_majun_disetor / v_total_perca_diambil;
    END IF;

    -- 6. Prediksi = sisa × reff
    v_prediksi_majun := v_sisa_perca * v_reff;

    RETURN QUERY
    SELECT
        v_sisa_perca,
        v_total_perca_diambil,
        v_total_majun_disetor,
        v_total_limbah_disetor,
        v_reff,
        v_prediksi_majun;
END;
$$;

-- Izinkan pemanggilan oleh user yang terautentikasi
GRANT EXECUTE ON FUNCTION get_tailor_efficiency_stats(UUID) TO authenticated;
