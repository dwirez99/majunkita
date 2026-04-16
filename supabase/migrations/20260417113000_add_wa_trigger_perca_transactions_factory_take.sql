-- ============================================================
-- MIGRATION: Add WA trigger for perca taking transactions
-- Date: 2026-04-17
--
-- Tujuan:
--   Mengirim notifikasi WhatsApp ke manager setiap ada pengambilan
--   perca oleh penjahit, dengan format:
--   - daftar semua karung/perca pada transaksi (jenis + berat)
--   - total karung & total berat
--   - menyertakan gambar dari pabrik (delivery_proof dari percas_stock)
--
-- Catatan:
--   - Trigger berjalan AFTER INSERT pada public.perca_transactions
--   - Karena transaksi bisa insert beberapa baris dalam waktu berdekatan,
--     trigger menggunakan pg_notify + debounce 2 detik agar 1 batch
--     menjadi 1 pesan teragregasi.
-- ============================================================

-- 1) Function worker: membangun pesan teragregasi dan enqueue WA
CREATE OR REPLACE FUNCTION public.fn_enqueue_wa_perca_take_grouped(
  p_tailor_id UUID,
  p_staff_id UUID,
  p_date_entry DATE,
  p_time_window_seconds INTEGER DEFAULT 2
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_manager RECORD;
  v_tailor_name TEXT;
  v_rows_count INTEGER := 0;
  v_total_weight NUMERIC := 0;
  v_details TEXT := '';
  v_image_url TEXT;
BEGIN
  -- Nama penjahit
  SELECT t.name
  INTO v_tailor_name
  FROM public.tailors t
  WHERE t.id = p_tailor_id;

  -- Ambil seluruh row transaksi dalam jendela waktu agar 1 batch jadi 1 pesan
  WITH picked AS (
    SELECT
      pt.id,
      pt.id_stock_perca,
      COALESCE(pt.percas_type, ps.perca_type, '-') AS perca_type,
      COALESCE(pt.weight, ps.weight, 0) AS weight,
      ps.sack_code,
      ps.delivery_proof,
      pt.created_at
    FROM public.perca_transactions pt
    LEFT JOIN public.percas_stock ps
      ON ps.id = pt.id_stock_perca
    WHERE pt.id_tailors = p_tailor_id
      AND COALESCE(pt.staff_id, p_staff_id) = p_staff_id
      AND pt.date_entry = p_date_entry
      AND pt.created_at >= now() - make_interval(secs => GREATEST(COALESCE(p_time_window_seconds, 2), 1))
  ),
  agg AS (
    SELECT
      COUNT(*)::INT AS cnt,
      COALESCE(SUM(weight), 0) AS total_weight,
      string_agg(
        format(
          E'• %s | Jenis: %s | Berat: %s kg',
          COALESCE(sack_code, '-'),
          COALESCE(perca_type, '-'),
          COALESCE(weight, 0)::TEXT
        ),
        E'\n'
        ORDER BY created_at ASC
      ) AS details
    FROM picked
  )
  SELECT
    a.cnt,
    a.total_weight,
    COALESCE(a.details, '')
  INTO
    v_rows_count,
    v_total_weight,
    v_details
  FROM agg a;

  -- Jika tidak ada data terpilih, hentikan
  IF COALESCE(v_rows_count, 0) = 0 THEN
    RETURN;
  END IF;

  -- Ambil satu gambar pabrik representatif dari batch (delivery_proof terbaru)
  SELECT p.delivery_proof
  INTO v_image_url
  FROM (
    SELECT
      ps.delivery_proof,
      pt.created_at
    FROM public.perca_transactions pt
    LEFT JOIN public.percas_stock ps
      ON ps.id = pt.id_stock_perca
    WHERE pt.id_tailors = p_tailor_id
      AND COALESCE(pt.staff_id, p_staff_id) = p_staff_id
      AND pt.date_entry = p_date_entry
      AND pt.created_at >= now() - make_interval(secs => GREATEST(COALESCE(p_time_window_seconds, 2), 1))
      AND ps.delivery_proof IS NOT NULL
      AND btrim(ps.delivery_proof) <> ''
    ORDER BY pt.created_at DESC
    LIMIT 1
  ) p;

  -- Kirim ke semua manager
  FOR v_manager IN
    SELECT p.no_telp
    FROM public.profiles p
    WHERE p.role::text = 'manager'
      AND p.no_telp IS NOT NULL
      AND btrim(p.no_telp) <> ''
  LOOP
    PERFORM public.enqueue_wa_notification(
      'pengambilan_perca',
      'perca_transactions',
      (
        SELECT pt.id
        FROM public.perca_transactions pt
        WHERE pt.id_tailors = p_tailor_id
          AND COALESCE(pt.staff_id, p_staff_id) = p_staff_id
          AND pt.date_entry = p_date_entry
        ORDER BY pt.created_at DESC
        LIMIT 1
      ),
      'manager',
      v_manager.no_telp,
      format(
        E'📥 *Pengambilan Perca dari Pabrik*\n\nTanggal: %s\nPenjahit: %s\nTotal Karung: %s\nTotal Berat: %s kg\n\n*Daftar Karung/Perca:*\n%s\n\nSilakan cek detail transaksi pada sistem.',
        p_date_entry::TEXT,
        COALESCE(v_tailor_name, '-'),
        v_rows_count::TEXT,
        COALESCE(v_total_weight, 0)::TEXT,
        v_details
      ),
      v_image_url
    );
  END LOOP;
END;
$$;

COMMENT ON FUNCTION public.fn_enqueue_wa_perca_take_grouped(UUID, UUID, DATE, INTEGER) IS
  'Membangun dan enqueue WA notifikasi pengambilan perca teragregasi (daftar karung, jenis, berat) + gambar pabrik.';

-- 2) Trigger function: debounce lalu panggil worker sekali per batch
CREATE OR REPLACE FUNCTION public.trg_enqueue_wa_perca_take()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_lock_key BIGINT;
BEGIN
  -- Advisory lock per kombinasi tailor+staff+tanggal untuk mencegah duplicate send
  v_lock_key := hashtextextended(
    COALESCE(NEW.id_tailors::TEXT, '-') || '|' ||
    COALESCE(NEW.staff_id::TEXT, '-') || '|' ||
    COALESCE(NEW.date_entry::TEXT, '-'),
    0
  );

  IF pg_try_advisory_xact_lock(v_lock_key) THEN
    -- Debounce singkat agar insert batch terkumpul
    PERFORM pg_sleep(2);

    PERFORM public.fn_enqueue_wa_perca_take_grouped(
      NEW.id_tailors,
      NEW.staff_id,
      NEW.date_entry,
      4
    );
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.trg_enqueue_wa_perca_take() IS
  'Trigger enqueue WA untuk pengambilan perca dengan debounce dan lock agar tidak duplicate.';

-- 3) Attach trigger
DROP TRIGGER IF EXISTS trg_enqueue_wa_perca_take ON public.perca_transactions;
CREATE TRIGGER trg_enqueue_wa_perca_take
  AFTER INSERT ON public.perca_transactions
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_enqueue_wa_perca_take();
