-- ============================================================
-- MIGRATION: Update get_admin_dashboard_summary
-- Date: 2026-03-05
--
-- Replaces the original function (20260210025721_remote_schema.sql)
-- with a comprehensive version that reflects the current schema:
--
--   • perca   — stock in warehouse (percas_stock) vs given to tailors
--               (perca_transactions), total distributed this month
--   • majun   — total received (majun_transactions.weight_majun),
--               total dispatched (expeditions.total_weight),
--               effective warehouse stock, total earned wages
--   • expedisi — total shipments, total sacks, total weight, this month
--   • penjahit — active count, total balance (unpaid wages),
--                total stock held across all tailors
--   • limbah  — total waste weight received
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_admin_dashboard_summary()
RETURNS json
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
SELECT json_build_object(

  -- ── 1. PERCA ─────────────────────────────────────────────────────────────
  'perca', json_build_object(
    -- Total stok perca di gudang pabrik
    'stok_gudang',
      COALESCE((SELECT SUM(weight) FROM public.percas_stock), 0),

    -- Total perca yang sudah diberikan ke penjahit (sepanjang waktu)
    'total_diberikan_ke_penjahit',
      COALESCE((SELECT SUM(weight) FROM public.perca_transactions), 0),

    -- Total perca yang didistribusikan bulan ini
    'distribusi_bulan_ini',
      COALESCE((
        SELECT SUM(weight) FROM public.perca_transactions
        WHERE date_trunc('month', created_at) = date_trunc('month', now())
      ), 0)
  ),

  -- ── 2. MAJUN ─────────────────────────────────────────────────────────────
  'majun', json_build_object(
    -- Total majun yang diterima dari penjahit (semua waktu)
    'total_diterima',
      COALESCE((SELECT SUM(weight_majun) FROM public.majun_transactions), 0),

    -- Total majun yang sudah dikirim via expedisi
    'total_terkirim',
      COALESCE((SELECT SUM(total_weight) FROM public.expeditions), 0),

    -- Stok efektif di gudang saat ini
    'stok_efektif',
      COALESCE((SELECT SUM(weight_majun) FROM public.majun_transactions), 0)
      - COALESCE((SELECT SUM(total_weight) FROM public.expeditions), 0),

    -- Total upah yang sudah dibayarkan ke penjahit
    'total_upah_dibayar',
      COALESCE((SELECT SUM(earned_wage) FROM public.majun_transactions), 0),

    -- Total majun bulan ini
    'diterima_bulan_ini',
      COALESCE((
        SELECT SUM(weight_majun) FROM public.majun_transactions
        WHERE date_trunc('month', created_at) = date_trunc('month', now())
      ), 0)
  ),

  -- ── 3. EXPEDISI ───────────────────────────────────────────────────────────
  'expedisi', json_build_object(
    -- Total pengiriman sepanjang waktu
    'total_pengiriman',
      COALESCE((SELECT COUNT(*) FROM public.expeditions), 0),

    -- Total karung yang dikirim
    'total_karung',
      COALESCE((SELECT SUM(sack_number) FROM public.expeditions), 0),

    -- Total berat yang dikirim (kg)
    'total_berat_kg',
      COALESCE((SELECT SUM(total_weight) FROM public.expeditions), 0),

    -- Pengiriman bulan ini
    'pengiriman_bulan_ini',
      COALESCE((
        SELECT COUNT(*) FROM public.expeditions
        WHERE date_trunc('month', expedition_date::timestamptz) = date_trunc('month', now())
      ), 0),

    -- Berat yang dikirim bulan ini
    'berat_bulan_ini',
      COALESCE((
        SELECT SUM(total_weight) FROM public.expeditions
        WHERE date_trunc('month', expedition_date::timestamptz) = date_trunc('month', now())
      ), 0)
  ),

  -- ── 4. PENJAHIT ──────────────────────────────────────────────────────────
  'penjahit', json_build_object(
    -- Jumlah penjahit terdaftar
    'jumlah_aktif',
      (SELECT COUNT(*) FROM public.tailors),

    -- Total stok perca yang sedang dipegang oleh penjahit
    'total_stok_penjahit',
      COALESCE((SELECT SUM(total_stock) FROM public.tailors), 0),

    -- Total saldo/upah yang belum ditarik (dari kolom balance di tailors)
    'total_saldo_belum_ditarik',
      COALESCE((SELECT SUM(balance) FROM public.tailors), 0)
  ),

  -- ── 5. LIMBAH ────────────────────────────────────────────────────────────
  'limbah', json_build_object(
    -- Total limbah yang diterima sepanjang waktu
    'total_diterima',
      COALESCE((SELECT SUM(weight_limbah) FROM public.limbah_transactions), 0),

    -- Total limbah bulan ini
    'diterima_bulan_ini',
      COALESCE((
        SELECT SUM(weight_limbah) FROM public.limbah_transactions
        WHERE date_trunc('month', created_at) = date_trunc('month', now())
      ), 0)
  )

);
$$;

REVOKE EXECUTE ON FUNCTION public.get_admin_dashboard_summary() FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.get_admin_dashboard_summary() TO authenticated;

COMMENT ON FUNCTION public.get_admin_dashboard_summary() IS
  'Comprehensive admin dashboard summary: perca stock, majun warehouse & dispatch, expeditions, tailors, limbah.';
