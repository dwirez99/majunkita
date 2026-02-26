-- 1. Tambah kolom sack_code pada percas_stock
-- Format: B-{weight} untuk Kain, K-{weight} untuk Kaos
ALTER TABLE public.percas_stock 
ADD COLUMN sack_code VARCHAR NOT NULL DEFAULT '-';

-- 2. Tambah kolom status pada percas_stock  
-- 'tersedia' = masih di gudang, 'diambil_penjahit' = sudah diberikan ke penjahit
ALTER TABLE public.percas_stock 
ADD COLUMN status VARCHAR NOT NULL DEFAULT 'tersedia';

-- 3. RPC: Proses transaksi perca berdasarkan sack_code
-- Menggunakan FIFO (karung terlama diambil duluan)
-- Otomatis update status stok dan insert ke perca_transactions
CREATE OR REPLACE FUNCTION public.process_transaction_by_sack_code(
  p_id_tailor UUID,
  p_staff_id UUID,
  p_sack_code VARCHAR,  -- Contoh: 'K-45'
  p_sack_count INT,     -- Contoh: 2 (bawa 2 karung K-45)
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

    -- 4. Update status karung di percas_stock
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
$$ LANGUAGE plpgsql;

-- 4. RPC: Ambil ringkasan stok tersedia per sack_code (untuk UI info)
CREATE OR REPLACE FUNCTION public.get_available_sack_summary()
RETURNS JSONB AS $$
BEGIN
  RETURN (
    SELECT COALESCE(jsonb_agg(row_data), '[]'::jsonb)
    FROM (
      SELECT jsonb_build_object(
        'sack_code', sack_code,
        'perca_type', perca_type,
        'total_sacks', count(*),
        'total_weight', sum(weight)
      ) AS row_data
      FROM public.percas_stock
      WHERE status = 'tersedia'
      GROUP BY sack_code, perca_type
      ORDER BY sack_code
    ) sub
  );
END;
$$ LANGUAGE plpgsql;