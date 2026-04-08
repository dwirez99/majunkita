-- ============================================================
-- MIGRATION: Secure get_tailor_efficiency_stats
-- Date: 2026-03-10
--
-- Adds role-based authorization check to get_tailor_efficiency_stats:
--   Only users with role 'admin' or 'manager' are allowed to call this
--   function. Any other authenticated user (e.g. penjahit, driver) will
--   receive an 'Akses ditolak' exception.
--
-- Background: the function uses SECURITY DEFINER which bypasses RLS,
-- so an explicit check inside the function body is required to prevent
-- any authenticated user from retrieving efficiency stats for any tailor.
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_tailor_efficiency_stats(p_tailor_id UUID)
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
    -- 0. Otorisasi: hanya admin atau manager yang boleh mengakses statistik ini.
    --    Fungsi ini memakai SECURITY DEFINER sehingga RLS di-bypass; pengecekan
    --    manual di sini menggantikan perlindungan yang biasanya diberikan RLS.
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Akses ditolak: pengguna belum terautentikasi.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE id = auth.uid()
          AND role IN ('admin', 'manager')
    ) THEN
        RAISE EXCEPTION 'Akses ditolak: hanya admin atau manager yang dapat melihat statistik efisiensi penjahit.';
    END IF;

    -- 1. Sisa perca saat ini (total_stock dari tailors).
    --    Gunakan scalar sub-select yang di-COALESCE agar v_sisa_perca tetap 0
    --    ketika p_tailor_id tidak ditemukan; SELECT ... INTO biasa akan
    --    menghasilkan NULL (meski variabel punya DEFAULT 0) dan menyebabkan
    --    prediksi_majun ikut NULL.
    SELECT COALESCE(
        (SELECT t.total_stock FROM tailors t WHERE t.id = p_tailor_id),
        0
    ) INTO v_sisa_perca;

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

-- Cabut default public privileges (SECURITY DEFINER tanpa REVOKE menyebabkan
-- role public masih mewarisi hak execute via default privileges), lalu berikan
-- secara eksplisit hanya ke authenticated. Pengecekan role di dalam fungsi
-- memastikan bahwa hanya admin/manager yang benar-benar dapat menggunakannya.
REVOKE EXECUTE ON FUNCTION public.get_tailor_efficiency_stats(UUID) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.get_tailor_efficiency_stats(UUID) TO authenticated;
