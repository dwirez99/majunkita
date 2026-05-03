-- ============================================================
-- MIGRATION: Fix WA Perca Take Batching via Bulk Insert
-- Date: 2026-05-03
--
-- Tujuan:
--   Mengubah PL/pgSQL FOR-LOOP tunggal pada process_transaction_by_sack_code
--   menjadi single-statement (CTE Bulk Insert). 
--   Karena menggunakan AFTER INSERT FOR EACH ROW trigger untuk batching,
--   insert melalui FOR-LOOP membuat trigger dieksekusi sebelum row selanjutnya
--   di-insert ke dalam transaksi, sehingga hanya row pertama yang ter-batch.
--   Dengan Bulk Insert, trigger AFTER INSERT baru akan dijalankan *setelah*
--   keseluruhan statement INSERT selesai, sehingga WA worker dapat melihat 
--   semua baris yang diinsert dan mem-batch-nya menjadi satu pesan utuh.
-- ============================================================

CREATE OR REPLACE FUNCTION public.process_transaction_by_sack_code(
  p_id_tailor UUID,
  p_staff_id UUID,
  p_sack_code VARCHAR,
  p_sack_count INT,
  p_date_entry DATE
) RETURNS JSONB AS $$
DECLARE
  v_sacks_available INT;
  v_total_weight NUMERIC := 0;
BEGIN
  -- 0. Validasi jumlah karung
  IF p_sack_count <= 0 THEN
    RAISE EXCEPTION 'Jumlah karung harus lebih dari 0, diterima: %.', p_sack_count;
  END IF;

  -- 0b. Pastikan pemanggil adalah staff yang terautentikasi dan p_staff_id cocok dengan sesi
  IF auth.uid() IS NULL OR auth.uid() != p_staff_id THEN
    RAISE EXCEPTION 'Akses ditolak: staff_id tidak sesuai dengan pengguna yang sedang login.';
  END IF;

  -- 1. Cek apakah jumlah karung DENGAN KODE TERSEBUT mencukupi
  SELECT count(*) INTO v_sacks_available
  FROM public.percas_stock
  WHERE status = 'tersedia' AND sack_code = p_sack_code;

  IF v_sacks_available < p_sack_count THEN
    RAISE EXCEPTION 'Stok karung % di gudang tidak cukup! Hanya sisa % karung.', p_sack_code, v_sacks_available;
  END IF;

  -- 2. Bulk Insert & Update via CTE
  WITH locked_sacks AS (
    SELECT id, perca_type, weight
    FROM public.percas_stock
    WHERE status = 'tersedia' AND sack_code = p_sack_code
    ORDER BY created_at ASC
    LIMIT p_sack_count
    FOR UPDATE SKIP LOCKED
  ),
  inserted_tx AS (
    INSERT INTO public.perca_transactions (
      id_stock_perca, id_tailors, date_entry, percas_type, weight, staff_id
    )
    SELECT id, p_id_tailor, p_date_entry, perca_type, weight, p_staff_id
    FROM locked_sacks
    RETURNING weight
  ),
  updated_sacks AS (
    UPDATE public.percas_stock ps
    SET status = 'diambil_penjahit'
    FROM locked_sacks
    WHERE ps.id = locked_sacks.id
  )
  SELECT COALESCE(SUM(weight), 0) INTO v_total_weight
  FROM inserted_tx;

  RETURN jsonb_build_object(
    'status', 'success', 
    'sack_code', p_sack_code,
    'sacks_taken', p_sack_count, 
    'total_weight_kg', v_total_weight
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Batasi EXECUTE hanya untuk role 'authenticated' (bukan public)
REVOKE EXECUTE ON FUNCTION public.process_transaction_by_sack_code(UUID, UUID, VARCHAR, INT, DATE) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.process_transaction_by_sack_code(UUID, UUID, VARCHAR, INT, DATE) TO authenticated;
