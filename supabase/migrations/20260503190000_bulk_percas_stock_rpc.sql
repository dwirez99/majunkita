-- ============================================================
-- MIGRATION: Bulk Percas Stock (Pabrik) RPC
-- Date: 2026-05-03
--
-- Tujuan:
-- Menggunakan pendekatan yang persis sama dengan Perca Take:
-- 1. Menghapus trigger AFTER INSERT.
-- 2. Membuat fungsi bulk RPC untuk insert list stok perca.
-- 3. Mengeksekusi pesan WA di akhir bulk insert HANYA 1 KALI.
-- Menjamin pesan ke manajer tidak pecah saat menambah stok dari pabrik.
-- ============================================================

DROP TRIGGER IF EXISTS trg_enqueue_wa_tambah_stok_perca ON public.percas_stock;
DROP FUNCTION IF EXISTS public.trg_enqueue_wa_tambah_stok_perca();

CREATE OR REPLACE FUNCTION public.process_bulk_percas_stock(
  p_items JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_total_weight NUMERIC := 0;
  v_total_sacks INTEGER := 0;
  v_factory_id UUID;
  v_date_entry DATE;
BEGIN
  IF jsonb_array_length(p_items) = 0 THEN
    RETURN jsonb_build_object('status', 'empty');
  END IF;

  -- Ambil factory_id dan date_entry dari item pertama
  v_factory_id := (p_items->0->>'id_factory')::UUID;
  v_date_entry := (p_items->0->>'date_entry')::DATE;

  -- 1. Insert multiple items sekaligus via jsonb_to_recordset
  INSERT INTO public.percas_stock (id_factory, date_entry, perca_type, weight, delivery_proof, sack_code, status)
  SELECT 
    (v.id_factory)::UUID,
    (v.date_entry)::DATE,
    v.perca_type,
    (v.weight)::NUMERIC,
    v.delivery_proof,
    v.sack_code,
    'tersedia'
  FROM jsonb_to_recordset(p_items) AS v(id_factory TEXT, date_entry TEXT, perca_type TEXT, weight NUMERIC, delivery_proof TEXT, sack_code TEXT);

  -- 2. Hitung total
  SELECT count(*), coalesce(sum((v.weight)::NUMERIC), 0)
  INTO v_total_sacks, v_total_weight
  FROM jsonb_to_recordset(p_items) AS v(weight NUMERIC);

  -- 3. Eksekusi pesan WA HANYA 1 KALI di akhir transaksi
  PERFORM public.fn_enqueue_wa_percas_stock_grouped(
    v_factory_id,
    v_date_entry,
    0
  );

  RETURN jsonb_build_object(
    'status', 'success',
    'total_weight_kg', v_total_weight,
    'total_sacks', v_total_sacks
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.process_bulk_percas_stock(JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.process_bulk_percas_stock(JSONB) TO authenticated;
