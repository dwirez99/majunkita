-- ============================================================
-- MIGRATION: Improve WA notification message templates (Bahasa Indonesia)
-- Date: 2026-04-17
--
-- Tujuan:
--   Memperjelas dan merapikan isi pesan WhatsApp agar lebih mudah dibaca
--   oleh penerima (penjahit/manager), dengan format konsisten dan ringkas.
--
-- Catatan:
--   - Tidak mengubah struktur tabel queue/log.
--   - Hanya memperbarui fungsi trigger pembuat pesan.
-- ============================================================

-- ============================================================
-- 1) Trigger: setor majun -> notifikasi ke penjahit
-- ============================================================
CREATE OR REPLACE FUNCTION public.trg_enqueue_wa_setor_majun()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tailor_name TEXT;
  v_tailor_phone TEXT;
BEGIN
  SELECT t.name, t.no_telp
  INTO v_tailor_name, v_tailor_phone
  FROM public.tailors t
  WHERE t.id = NEW.id_tailor;

  PERFORM public.enqueue_wa_notification(
    'setor_majun',
    'majun_transactions',
    NEW.id,
    'penjahit',
    v_tailor_phone,
    format(
      E'✅ *Konfirmasi Setor Majun*\n\nID Transaksi: #%s\nNama Penjahit: %s\nBerat Majun: %s kg\nUpah Diperoleh: Rp%s\n\nTerima kasih, setoran Anda sudah kami catat.',
      NEW.id::text,
      COALESCE(v_tailor_name, '-'),
      COALESCE(NEW.weight_majun, 0)::text,
      COALESCE(NEW.earned_wage, 0)::text
    ),
    NEW.delivery_proof
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enqueue_wa_setor_majun ON public.majun_transactions;
CREATE TRIGGER trg_enqueue_wa_setor_majun
  AFTER INSERT ON public.majun_transactions
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_enqueue_wa_setor_majun();

-- ============================================================
-- 2) Trigger: tambah stok perca -> notifikasi ke manager
-- ============================================================
CREATE OR REPLACE FUNCTION public.trg_enqueue_wa_tambah_stok_perca()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_manager RECORD;
  v_factory_name TEXT;
BEGIN
  SELECT f.factory_name
  INTO v_factory_name
  FROM public.factories f
  WHERE f.id = NEW.id_factory;

  FOR v_manager IN
    SELECT p.no_telp
    FROM public.profiles p
    WHERE p.role::text = 'manager'
      AND p.no_telp IS NOT NULL
      AND btrim(p.no_telp) <> ''
  LOOP
    PERFORM public.enqueue_wa_notification(
      'tambah_stok_perca',
      'percas_stock',
      NEW.id,
      'manager',
      v_manager.no_telp,
      format(
        E'📦 *Stok Perca Baru*\n\nAsal Pabrik: %s\nJenis Perca: %s\nBerat: %s kg\n\nSilakan cek detail stok pada sistem.',
        COALESCE(v_factory_name, '-'),
        COALESCE(NEW.perca_type, '-'),
        COALESCE(NEW.weight, 0)::text
      ),
      NEW.delivery_proof
    );
  END LOOP;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enqueue_wa_tambah_stok_perca ON public.percas_stock;
CREATE TRIGGER trg_enqueue_wa_tambah_stok_perca
  AFTER INSERT ON public.percas_stock
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_enqueue_wa_tambah_stok_perca();

-- ============================================================
-- 3) Trigger: expedition -> notifikasi ke manager
-- ============================================================
CREATE OR REPLACE FUNCTION public.trg_enqueue_wa_expedition()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_manager RECORD;
BEGIN
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
        E'🚚 *Update Pengiriman Majun*\n\nID Pengiriman: #%s\nTujuan/Karung: %s\nTotal Berat: %s kg\n\nMohon tindak lanjuti sesuai proses operasional.',
        NEW.id::text,
        COALESCE(NEW.destination, '-'),
        COALESCE(NEW.total_weight, 0)::text
      ),
      NEW.proof_of_delivery
    );
  END LOOP;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enqueue_wa_expedition ON public.expeditions;
CREATE TRIGGER trg_enqueue_wa_expedition
  AFTER INSERT ON public.expeditions
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_enqueue_wa_expedition();

-- ============================================================
-- 4) Trigger: penarikan upah -> notifikasi ke penjahit
-- ============================================================
CREATE OR REPLACE FUNCTION public.trg_enqueue_wa_salary_withdrawal()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tailor_name TEXT;
  v_tailor_phone TEXT;
  v_current_balance NUMERIC;
BEGIN
  SELECT t.name, t.no_telp, COALESCE(t.balance, 0)
  INTO v_tailor_name, v_tailor_phone, v_current_balance
  FROM public.tailors t
  WHERE t.id = NEW.id_tailor;

  PERFORM public.enqueue_wa_notification(
    'penarikan_upah',
    'salary_withdrawals',
    NEW.id_tailor,
    'penjahit',
    v_tailor_phone,
    format(
      E'💸 *Konfirmasi Penarikan Upah*\n\nID Penarikan: #%s\nNama Penjahit: %s\nNominal Ditarik: Rp%s\nEstimasi Sisa Saldo: Rp%s\n\nJika ada ketidaksesuaian, silakan hubungi admin.',
      NEW.id::text,
      COALESCE(v_tailor_name, '-'),
      COALESCE(NEW.amount, 0)::text,
      GREATEST(v_current_balance - COALESCE(NEW.amount, 0), 0)::text
    ),
    NULL
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enqueue_wa_salary_withdrawal ON public.salary_withdrawals;
CREATE TRIGGER trg_enqueue_wa_salary_withdrawal
  AFTER INSERT ON public.salary_withdrawals
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_enqueue_wa_salary_withdrawal();

COMMENT ON FUNCTION public.trg_enqueue_wa_setor_majun() IS
  'Enqueue WA notifikasi setor majun dengan template Bahasa Indonesia yang lebih jelas.';

COMMENT ON FUNCTION public.trg_enqueue_wa_tambah_stok_perca() IS
  'Enqueue WA notifikasi stok perca baru ke manager dengan template Bahasa Indonesia yang lebih mudah dibaca.';

COMMENT ON FUNCTION public.trg_enqueue_wa_expedition() IS
  'Enqueue WA notifikasi update pengiriman majun ke manager dengan template Bahasa Indonesia yang ringkas.';

COMMENT ON FUNCTION public.trg_enqueue_wa_salary_withdrawal() IS
  'Enqueue WA notifikasi konfirmasi penarikan upah dengan template Bahasa Indonesia yang lebih jelas.';
