-- Fix: Update process_transaction_by_sack_code function
-- 1. Ganti status dari 'terambil' menjadi 'diambil_penjahit'
-- 2. Tambah SECURITY DEFINER agar bisa bypass RLS (tidak ada UPDATE policy di percas_stock)
CREATE OR REPLACE FUNCTION public.process_transaction_by_sack_code(
  p_id_tailor UUID,
  p_staff_id UUID,
  p_sack_code VARCHAR,
  p_sack_count INT,
  p_date_entry DATE
) RETURNS JSONB AS $$
DECLARE
  v_sack RECORD;
  v_sacks_available INT;
  v_total_weight NUMERIC := 0;
BEGIN
  -- 1. Cek apakah jumlah karung DENGAN KODE TERSEBUT mencukupi
  SELECT count(*) INTO v_sacks_available
  FROM public.percas_stock
  WHERE status = 'tersedia' AND sack_code = p_sack_code;

  IF v_sacks_available < p_sack_count THEN
    RAISE EXCEPTION 'Stok karung % di gudang tidak cukup! Hanya sisa % karung.', p_sack_code, v_sacks_available;
  END IF;

  -- 2. Loop FIFO: Cari N karung terlama DENGAN KODE TERSEBUT
  FOR v_sack IN
    SELECT * FROM public.percas_stock
    WHERE status = 'tersedia' AND sack_code = p_sack_code
    ORDER BY created_at ASC
    LIMIT p_sack_count
  LOOP
    -- 3. Insert ke perca_transactions
    INSERT INTO public.perca_transactions (
      id_stock_perca, id_tailors, date_entry, percas_type, weight, staff_id
    ) VALUES (
      v_sack.id, p_id_tailor, p_date_entry, v_sack.perca_type, v_sack.weight, p_staff_id
    );

    -- 4. Update status karung di percas_stock → 'diambil_penjahit'
    UPDATE public.percas_stock
    SET status = 'diambil_penjahit'
    WHERE id = v_sack.id;

    -- 5. Hitung total berat
    v_total_weight := v_total_weight + v_sack.weight;
  END LOOP;

  RETURN jsonb_build_object(
    'status', 'success', 
    'sack_code', p_sack_code,
    'sacks_taken', p_sack_count, 
    'total_weight_kg', v_total_weight
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
