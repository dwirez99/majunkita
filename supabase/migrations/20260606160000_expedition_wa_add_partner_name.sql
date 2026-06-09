-- ============================================================
-- MIGRATION: Replace id_expedition_partner FK with
--            expedition_partner_name TEXT column, and update
--            the WA notification trigger to include partner info.
-- Date: 2026-06-06
--
-- Tujuan:
--   1. Denormalisasi: ganti kolom FK id_expedition_partner (UUID)
--      dengan expedition_partner_name (TEXT) langsung di tabel expeditions.
--   2. Backfill data dari tabel expedition_partners.
--   3. Update trigger WA notifikasi expedisi agar menampilkan
--      mitra pengiriman, driver, jumlah karung, dan total berat.
-- ============================================================

-- 1. Add new TEXT column
ALTER TABLE public.expeditions
  ADD COLUMN IF NOT EXISTS expedition_partner_name TEXT;

-- 2. Backfill existing records from expedition_partners JOIN
UPDATE public.expeditions e
SET expedition_partner_name = ep.name
FROM public.expedition_partners ep
WHERE e.id_expedition_partner = ep.id
  AND e.expedition_partner_name IS NULL;

-- 3. Drop the old FK column
ALTER TABLE public.expeditions
  DROP COLUMN IF EXISTS id_expedition_partner;

-- ============================================================
-- 4. Update WA trigger to include mitra pengiriman & driver
-- ============================================================
CREATE OR REPLACE FUNCTION public.trg_enqueue_wa_expedition()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_manager RECORD;
  v_driver_name TEXT;
BEGIN
  -- Ambil nama driver dari tabel profiles
  IF NEW.id_partner IS NOT NULL THEN
    SELECT p.name
    INTO v_driver_name
    FROM public.profiles p
    WHERE p.id = NEW.id_partner;
  END IF;

  FOR v_manager IN
    SELECT p.no_telp
    FROM public.profiles p
    WHERE p.role::text = 'manager'
      AND p.no_telp IS NOT NULL
      AND btrim(p.no_telp) <> ''
  LOOP
    PERFORM public.enqueue_wa_notification(
      'expedition',
      'expeditions',
      NEW.id,
      'manager',
      v_manager.no_telp,
      format(
        E'🚚 *Update Pengiriman Majun*\n\nTujuan: %s\nMitra Pengiriman: %s\nDriver: %s\nJumlah Karung: %s\nTotal Berat: %s kg\n\nMohon tindak lanjuti sesuai proses operasional.',
        COALESCE(NEW.destination, '-'),
        COALESCE(NEW.expedition_partner_name, '-'),
        COALESCE(v_driver_name, '-'),
        COALESCE(NEW.sack_number, 0)::text,
        COALESCE(NEW.total_weight, 0)::text
      ),
      NEW.proof_of_delivery
    );
  END LOOP;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.trg_enqueue_wa_expedition() IS
  'Enqueue WA notifikasi expedisi ke manager. Menampilkan tujuan, mitra pengiriman, driver, jumlah karung, dan total berat.';
