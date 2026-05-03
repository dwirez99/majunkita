-- ============================================================
-- MIGRATION: Bulk Perca Take RPC
-- Date: 2026-05-03
--
-- Tujuan:
-- Menyelesaikan tuntas masalah pesan terpecah akibat keterbatasan 
-- koneksi klien dan pg_sleep. 
-- 1. Kita menghapus trigger AFTER INSERT.
-- 2. Kita membuat fungsi bulk RPC yang menerima JSON array karung.
-- 3. Di dalam bulk RPC, insert dilakukan secepat kilat tanpa sleep.
-- 4. Di akhir bulk RPC, barulah fungsi WA worker dipanggil 1 KALI saja.
-- Dengan ini, pesan dijamin 1000% tidak akan pernah terpisah lagi.
-- ============================================================

DROP TRIGGER IF EXISTS trg_enqueue_wa_perca_take ON public.perca_transactions;
DROP FUNCTION IF EXISTS public.trg_enqueue_wa_perca_take();

CREATE OR REPLACE FUNCTION public.process_bulk_transactions_by_sack_codes(
  p_id_tailor UUID,
  p_staff_id UUID,
  p_date_entry DATE,
  p_items JSONB -- Format: '[{"sackCode": "B-108", "sackCount": 2}, {"sackCode": "K-15", "sackCount": 1}]'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_item JSONB;
  v_sack_code TEXT;
  v_sack_count INTEGER;
  v_total_weight NUMERIC := 0;
  v_total_sacks INTEGER := 0;
  v_json_res JSONB;
BEGIN
  -- Lakukan loop terhadap setiap item
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    v_sack_code := v_item->>'sackCode';
    v_sack_count := (v_item->>'sackCount')::INTEGER;

    -- Panggil fungsi existing untuk update stok dan insert transaksi per sack code
    v_json_res := public.process_transaction_by_sack_code(
      p_id_tailor,
      p_staff_id,
      v_sack_code,
      v_sack_count,
      p_date_entry
    );

    v_total_weight := v_total_weight + COALESCE((v_json_res->>'total_weight_kg')::NUMERIC, 0);
    v_total_sacks := v_total_sacks + COALESCE((v_json_res->>'sacks_taken')::INTEGER, 0);
  END LOOP;

  -- Panggil fungsi WA worker SECARA MANUAL HANYA 1 KALI di akhir transaksi bulk!
  -- Kita set p_time_window_seconds = 0 karena semua data sudah pasti tersimpan
  -- dan siap di-batch tanpa perlu menunggu/sleep lagi.
  PERFORM public.fn_enqueue_wa_perca_take_grouped(
    p_id_tailor,
    p_staff_id,
    p_date_entry,
    0
  );

  RETURN jsonb_build_object(
    'status', 'success',
    'total_weight_kg', v_total_weight,
    'total_sacks_taken', v_total_sacks
  );
END;
$$;

-- Batasi akses
REVOKE EXECUTE ON FUNCTION public.process_bulk_transactions_by_sack_codes(UUID, UUID, DATE, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.process_bulk_transactions_by_sack_codes(UUID, UUID, DATE, JSONB) TO authenticated;
