-- ============================================================
-- SEED.SQL — MajunKita Development Data Seeder
-- ============================================================
--
-- ⚠️  PERINGATAN / WARNING:
--     Script ini akan MENGHAPUS SEMUA DATA yang ada di database.
--     BACKUP data penting sebelum menjalankan!
--     JANGAN jalankan di database PRODUCTION!
--
-- Cara Menjalankan:
--   1. Via Supabase SQL Editor:
--      - Buka project di https://app.supabase.com
--      - Pergi ke menu SQL Editor
--      - Copy-paste seluruh isi file ini dan klik "Run"
--
--   2. Via psql CLI:
--      psql -h <host> -U <user> -d <database> -f supabase/seed.sql
--
-- Konten yang di-seed:
--   - 3  expedition_partners (mitra ekspedisi)
--   - 5  factories / pabrik
--   - 22 tailors / penjahit (lebih dari minimal 20)
--   - Stok perca dari pabrik: 5.145 KG total (15 bulan, nilai tepat)
--   - Distribusi perca ke penjahit (15 bulan: Jan 2025 – Mar 2026)
--   - Setor majun (mulai bulan ke-3, 13 bulan)
--   - Setor limbah (mulai bulan ke-4, 12 bulan)
--   - Catatan gaji / salary (per 2 bulan)
--   - Penarikan gaji / salary_withdrawals (mulai bulan ke-5)
--   - Stok majun di gudang / majun_stock
--
-- CATATAN:
--   Tabel `profiles` tidak di-seed karena bergantung pada
--   Supabase Auth (auth.users). Buat user melalui aplikasi
--   atau Supabase Dashboard terlebih dahulu.
--
--   Tabel `expeditions` tidak di-seed karena membutuhkan
--   id_partner yang mengacu ke profiles.id (auth user).
-- ============================================================

BEGIN;

-- ============================================================
-- LANGKAH 0: Nonaktifkan trigger WA enqueue sementara
--
-- Beberapa trigger WA grouped melakukan pg_sleep() untuk debounce,
-- yang bisa memicu statement timeout saat bulk insert seed.
--
-- Hanya trigger notifikasi WA yang dinonaktifkan (prefix:
-- trg_enqueue_wa_), trigger bisnis lain tetap aktif.
-- ============================================================
DO $$
DECLARE
  v_trigger RECORD;
BEGIN
  FOR v_trigger IN
    SELECT
      n.nspname AS schema_name,
      c.relname AS table_name,
      t.tgname  AS trigger_name
    FROM pg_trigger t
    JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE NOT t.tgisinternal
      AND n.nspname = 'public'
      AND t.tgname LIKE 'trg_enqueue_wa_%'
  LOOP
    EXECUTE format(
      'ALTER TABLE %I.%I DISABLE TRIGGER %I',
      v_trigger.schema_name,
      v_trigger.table_name,
      v_trigger.trigger_name
    );
  END LOOP;
END $$;

-- ============================================================
-- LANGKAH 1: TRUNCATE semua tabel aplikasi
-- Urutan dari tabel "anak" ke "induk" agar FK tidak conflict.
-- RESTART IDENTITY mereset sequence ID ke awal.
-- CASCADE otomatis truncate tabel dependen jika ada.
-- ============================================================
TRUNCATE TABLE
  public.wa_notification_logs,
  public.wa_notification_queue,
  public.salary_withdrawals,
  public.salary,
  public.majun_transactions,
  public.limbah_transactions,
  public.majun_stock,
  public.perca_transactions,
  public.expeditions,
  public.percas_stock,
  public.expedition_partners,
  public.tailors,
  public.factories,
  public.app_settings
RESTART IDENTITY CASCADE;

-- ============================================================
-- LANGKAH 2: Konfigurasi Aplikasi (app_settings)
-- Harga standar majun diperlukan oleh trigger majun_transactions.
-- ============================================================
INSERT INTO public.app_settings (key, value, description)
VALUES (
  'majun_price_per_kg',
  '1500',
  'Harga standar majun per kilogram (Rupiah)'
);

-- ============================================================
-- LANGKAH 3: Mitra Ekspedisi (expedition_partners) — 3 mitra
-- ============================================================
INSERT INTO public.expedition_partners (id, name, no_telp, address) VALUES
  (
    '00000000-0000-0000-0000-e00000000001',
    'JNE Express',
    '021-29278888',
    'Jl. Tomang Raya No. 11, Jakarta Barat'
  ),
  (
    '00000000-0000-0000-0000-e00000000002',
    'TIKI Jalur Nugraha Ekakurir',
    '021-80880888',
    'Jl. Cikini Raya No. 55, Jakarta Pusat'
  ),
  (
    '00000000-0000-0000-0000-e00000000003',
    'SiCepat Ekspres',
    '021-50200050',
    'Jl. Gajah Mada No. 100, Jakarta Pusat'
  );

-- ============================================================
-- LANGKAH 4: Pabrik / Factories — 5 pabrik
-- UUID format: 00000000-0000-0000-0000-f000000000XX
-- ============================================================
INSERT INTO public.factories (id, factory_name, address, no_telp) VALUES
  (
    '00000000-0000-0000-0000-f00000000001',
    'PT. Tekstil Nusantara',
    'Jl. Industri Raya No. 10, Kawasan Industri Bandung, Jawa Barat',
    '022-6123456'
  ),
  (
    '00000000-0000-0000-0000-f00000000002',
    'CV. Kain Makmur Sejahtera',
    'Jl. Gatot Subroto No. 45, Surabaya, Jawa Timur',
    '031-7654321'
  ),
  (
    '00000000-0000-0000-0000-f00000000003',
    'PT. Garmen Prima Indonesia',
    'Jl. Raya Bogor KM. 12, Cimanggis, Depok, Jawa Barat',
    '021-8765432'
  ),
  (
    '00000000-0000-0000-0000-f00000000004',
    'UD. Bahan Sandang Jaya',
    'Jl. Pemuda No. 88, Semarang, Jawa Tengah',
    '024-3456789'
  ),
  (
    '00000000-0000-0000-0000-f00000000005',
    'PT. Indo Tekstil Mandiri',
    'Jl. Sisingamangaraja No. 22, Medan, Sumatera Utara',
    '061-4567890'
  );

-- ============================================================
-- LANGKAH 5: Penjahit / Tailors — 22 penjahit
-- total_stock & balance diinisialisasi 0, akan diperbarui
-- oleh trigger saat data transaksi di-insert.
-- UUID format: 00000000-0000-0000-0000-b000000000XX
-- ============================================================
INSERT INTO public.tailors (id, name, no_telp, address, total_stock, balance) VALUES
  (
    '00000000-0000-0000-0000-b00000000001',
    'Siti Rahayu',
    '08112345001',
    'Jl. Melati No. 3, Cimahi, Jawa Barat',
    0, 0
  ),
  (
    '00000000-0000-0000-0000-b00000000002',
    'Dewi Lestari',
    '08112345002',
    'Jl. Mawar No. 7, Bandung, Jawa Barat',
    0, 0
  ),
  (
    '00000000-0000-0000-0000-b00000000003',
    'Ani Susanti',
    '08112345003',
    'Jl. Kenanga No. 15, Bekasi, Jawa Barat',
    0, 0
  ),
  (
    '00000000-0000-0000-0000-b00000000004',
    'Rina Marlina',
    '08112345004',
    'Jl. Anggrek No. 9, Bogor, Jawa Barat',
    0, 0
  ),
  (
    '00000000-0000-0000-0000-b00000000005',
    'Nining Kurniawati',
    '08112345005',
    'Jl. Flamboyan No. 22, Tangerang, Banten',
    0, 0
  ),
  (
    '00000000-0000-0000-0000-b00000000006',
    'Tini Sumarni',
    '08112345006',
    'Jl. Tulip No. 4, Depok, Jawa Barat',
    0, 0
  ),
  (
    '00000000-0000-0000-0000-b00000000007',
    'Yuli Andriyani',
    '08112345007',
    'Jl. Dahlia No. 11, Cikarang, Jawa Barat',
    0, 0
  ),
  (
    '00000000-0000-0000-0000-b00000000008',
    'Sri Wahyuni',
    '08112345008',
    'Jl. Cempaka No. 6, Surabaya, Jawa Timur',
    0, 0
  ),
  (
    '00000000-0000-0000-0000-b00000000009',
    'Eti Nurhayati',
    '08112345009',
    'Jl. Seruni No. 18, Malang, Jawa Timur',
    0, 0
  ),
  (
    '00000000-0000-0000-0000-b00000000010',
    'Wati Purwaningsih',
    '08112345010',
    'Jl. Teratai No. 30, Semarang, Jawa Tengah',
    0, 0
  ),
  (
    '00000000-0000-0000-0000-b00000000011',
    'Endang Supriyati',
    '08112345011',
    'Jl. Nusa Indah No. 8, Solo, Jawa Tengah',
    0, 0
  ),
  (
    '00000000-0000-0000-0000-b00000000012',
    'Komariah Santoso',
    '08112345012',
    'Jl. Pahlawan No. 5, Yogyakarta, DIY',
    0, 0
  ),
  (
    '00000000-0000-0000-0000-b00000000013',
    'Lilis Setiawati',
    '08112345013',
    'Jl. Diponegoro No. 2, Semarang, Jawa Tengah',
    0, 0
  ),
  (
    '00000000-0000-0000-0000-b00000000014',
    'Mirah Darsono',
    '08112345014',
    'Jl. Sudirman No. 17, Bandung, Jawa Barat',
    0, 0
  ),
  (
    '00000000-0000-0000-0000-b00000000015',
    'Parti Wijaya',
    '08112345015',
    'Jl. Ahmad Yani No. 44, Surakarta, Jawa Tengah',
    0, 0
  ),
  (
    '00000000-0000-0000-0000-b00000000016',
    'Sumiati Rahayu',
    '08112345016',
    'Jl. Gatot Subroto No. 33, Tangerang Selatan, Banten',
    0, 0
  ),
  (
    '00000000-0000-0000-0000-b00000000017',
    'Hasanah Yulianti',
    '08112345017',
    'Jl. Merdeka No. 12, Bandung, Jawa Barat',
    0, 0
  ),
  (
    '00000000-0000-0000-0000-b00000000018',
    'Fatimah Zainab',
    '08112345018',
    'Jl. Kartini No. 27, Medan, Sumatera Utara',
    0, 0
  ),
  (
    '00000000-0000-0000-0000-b00000000019',
    'Nurul Hidayah',
    '08112345019',
    'Jl. Proklamasi No. 7, Makassar, Sulawesi Selatan',
    0, 0
  ),
  (
    '00000000-0000-0000-0000-b00000000020',
    'Sari Indah Permata',
    '08112345020',
    'Jl. Veteran No. 39, Palembang, Sumatera Selatan',
    0, 0
  ),
  (
    '00000000-0000-0000-0000-b00000000021',
    'Budi Handoyo',
    '08112345021',
    'Jl. Cendana No. 14, Cirebon, Jawa Barat',
    0, 0
  ),
  (
    '00000000-0000-0000-0000-b00000000022',
    'Agus Santoso',
    '08112345022',
    'Jl. Jendral Sudirman No. 6, Pekalongan, Jawa Tengah',
    0, 0
  );

-- ============================================================
-- LANGKAH 6: Data Time-Series (15 bulan: Jan 2025 – Mar 2026)
--
-- Urutan INSERT sangat penting untuk menjaga CHECK constraint
-- total_stock >= 0 pada tabel tailors:
--   (a) percas_stock    → stok dari pabrik
--   (b) perca_transactions → distribusi ke penjahit (total_stock naik)
--   (c) majun_transactions  → setor majun (total_stock turun)
--   (d) limbah_transactions → setor limbah (total_stock turun)
--   (e) salary          → catatan gaji historis (setiap 2 bulan)
--   (f) salary_withdrawals  → penarikan gaji
--   (g) majun_stock     → stok majun di gudang
--
-- Formula deterministik (tidak pakai random()) memastikan:
--   - Hasil seed IDENTIK setiap kali dijalankan
--   - total_stock penjahit TIDAK pernah negatif selama insert
--
-- Garansi matematis total_stock >= 0:
--   Setiap bulan: perca_diterima >= (majun_disetor + limbah_disetor)
--   Karena majun = floor(perca_2_bulan_lalu / 2)  ≤ perca
--   Dan  limbah = floor(perca_3_bulan_lalu × 15 / 100) << perca
-- ============================================================
DO $$
DECLARE
  -- Factory UUIDs (harus cocok dengan INSERT di Langkah 4)
  v_factory_ids UUID[] := ARRAY[
    '00000000-0000-0000-0000-f00000000001'::UUID,
    '00000000-0000-0000-0000-f00000000002'::UUID,
    '00000000-0000-0000-0000-f00000000003'::UUID,
    '00000000-0000-0000-0000-f00000000004'::UUID,
    '00000000-0000-0000-0000-f00000000005'::UUID
  ];

  -- Tailor UUIDs (harus cocok dengan INSERT di Langkah 5)
  v_tailor_ids UUID[] := ARRAY[
    '00000000-0000-0000-0000-b00000000001'::UUID,
    '00000000-0000-0000-0000-b00000000002'::UUID,
    '00000000-0000-0000-0000-b00000000003'::UUID,
    '00000000-0000-0000-0000-b00000000004'::UUID,
    '00000000-0000-0000-0000-b00000000005'::UUID,
    '00000000-0000-0000-0000-b00000000006'::UUID,
    '00000000-0000-0000-0000-b00000000007'::UUID,
    '00000000-0000-0000-0000-b00000000008'::UUID,
    '00000000-0000-0000-0000-b00000000009'::UUID,
    '00000000-0000-0000-0000-b00000000010'::UUID,
    '00000000-0000-0000-0000-b00000000011'::UUID,
    '00000000-0000-0000-0000-b00000000012'::UUID,
    '00000000-0000-0000-0000-b00000000013'::UUID,
    '00000000-0000-0000-0000-b00000000014'::UUID,
    '00000000-0000-0000-0000-b00000000015'::UUID,
    '00000000-0000-0000-0000-b00000000016'::UUID,
    '00000000-0000-0000-0000-b00000000017'::UUID,
    '00000000-0000-0000-0000-b00000000018'::UUID,
    '00000000-0000-0000-0000-b00000000019'::UUID,
    '00000000-0000-0000-0000-b00000000020'::UUID,
    '00000000-0000-0000-0000-b00000000021'::UUID,
    '00000000-0000-0000-0000-b00000000022'::UUID
  ];

  v_perca_types TEXT[] := ARRAY[
    'kain', 'kaos'
  ];

  -- Array untuk menyimpan UUID percas_stock yang baru dibuat,
  -- agar bisa direferensikan di perca_transactions.
  v_perca_stock_ids UUID[];

  -- Loop variables
  v_month_num       INT;
  v_shipment_num    INT;
  v_tailor_idx      INT;
  v_month_date      DATE;
  v_stock_id        UUID;
  v_stock_arr_idx   INT;
  v_weight          NUMERIC;
  v_perca_ref       NUMERIC;
  v_sack_code       TEXT;

BEGIN
  v_perca_stock_ids := ARRAY[]::UUID[];

  -- ==========================================================
  -- (a) percas_stock: Stok perca dari pabrik
  --     15 bulan × 3 pengiriman/bulan = 45 baris
  --     Total berat: 5.145 KG tepat (formula deterministik)
  --
  --     Formula berat: 100 + ((bulan × 7 + pengiriman × 13) % 30)
  --     Rentang: 100 – 129 KG per pengiriman
  -- ==========================================================
  FOR v_month_num IN 0..14 LOOP
    v_month_date := DATE '2025-01-01' + (v_month_num * INTERVAL '1 month');

    FOR v_shipment_num IN 1..3 LOOP
      v_stock_id := gen_random_uuid();
      v_weight   := 100 + ((v_month_num * 7 + v_shipment_num * 13) % 30);

      -- sack_code: K-{weight} untuk kaos, B-{weight} untuk kain
      -- Format berat: integer tanpa desimal (weight selalu bilangan bulat di sini)
      v_sack_code :=
        CASE v_perca_types[((v_month_num + v_shipment_num) % 2) + 1]
          WHEN 'kaos' THEN 'K-' || trunc(v_weight)::TEXT
          ELSE              'B-' || trunc(v_weight)::TEXT
        END;

      INSERT INTO public.percas_stock
        (id, id_factory, date_entry, perca_type, weight, sack_code, delivery_proof)
      VALUES (
        v_stock_id,
        v_factory_ids[((v_month_num * 3 + v_shipment_num - 1) % 5) + 1],
        v_month_date + ((v_shipment_num - 1) * 10),
        v_perca_types[((v_month_num + v_shipment_num) % 2) + 1],
        v_weight,
        v_sack_code,
        'SJ/' || TO_CHAR(v_month_date, 'YYYYMM') || '/' ||
          LPAD((v_month_num * 3 + v_shipment_num)::TEXT, 4, '0')
      );

      v_perca_stock_ids := array_append(v_perca_stock_ids, v_stock_id);
    END LOOP;
  END LOOP;

  -- ==========================================================
  -- (b) perca_transactions: Distribusi perca ke setiap penjahit
  --     22 penjahit × 15 bulan = 330 baris
  --     Total didistribusikan: 4.115 KG (< stok pabrik 5.145 KG)
  --
  --     Formula berat per penjahit per bulan:
  --       8 + ((tailor_idx × 3 + bulan × 7) % 10) = 8 – 17 KG
  --
  --     Trigger trg_perca_add_stock akan menaikkan
  --     tailors.total_stock secara otomatis.
  -- ==========================================================
  FOR v_month_num IN 0..14 LOOP
    v_month_date := DATE '2025-01-01' + (v_month_num * INTERVAL '1 month');

    FOR v_tailor_idx IN 0..21 LOOP
      -- Pilih stock entry untuk bulan ini (3 stock per bulan, rotate)
      v_stock_arr_idx := (v_month_num * 3) + (v_tailor_idx % 3) + 1;
      v_weight := 8 + ((v_tailor_idx * 3 + v_month_num * 7) % 10);

      INSERT INTO public.perca_transactions
        (id, id_stock_perca, id_tailors, date_entry, percas_type, weight)
      VALUES (
        gen_random_uuid(),
        v_perca_stock_ids[v_stock_arr_idx],
        v_tailor_ids[v_tailor_idx + 1],
        v_month_date + (v_tailor_idx % 20),
  v_perca_types[((v_month_num + v_tailor_idx) % 2) + 1],
        v_weight
      );
    END LOOP;
  END LOOP;

  -- ==========================================================
  -- (c) majun_transactions: Penjahit setor lap majun
  --     22 penjahit × 13 bulan (mulai bulan ke-3) = 286 baris
  --
  --     Formula berat:
  --       GREATEST(1, floor(perca_2_bulan_lalu / 2))
  --       Jaminan matematis: total_majun ≤ total_perca / 2 < total_perca
  --       sehingga tailors.total_stock TIDAK PERNAH negatif.
  --
  --     Trigger trg_majun_calc_wage  → hitung earned_wage otomatis
  --     Trigger trg_majun_update_tailor → kurangi total_stock,
  --                                        tambah balance penjahit
  -- ==========================================================
  FOR v_month_num IN 2..14 LOOP
    v_month_date := DATE '2025-01-01' + (v_month_num * INTERVAL '1 month');
4
    FOR v_tailor_idx IN 0..21 LOOP
      -- Referensi perca yang diterima 2 bulan lalu
      v_perca_ref := 8 + ((v_tailor_idx * 3 + (v_month_num - 2) * 7) % 10);
      v_weight    := GREATEST(1, FLOOR(v_perca_ref / 2));

      INSERT INTO public.majun_transactions
        (id, id_tailor, date_entry, weight_majun, earned_wage, delivery_proof)
      VALUES (
        gen_random_uuid(),
        v_tailor_ids[v_tailor_idx + 1],
        v_month_date + (v_tailor_idx % 20),
        v_weight,
        0,   -- akan otomatis dihitung oleh trigger trg_majun_calc_wage
        'MJN/' || TO_CHAR(v_month_date, 'YYYYMM') || '/' ||
          LPAD((v_tailor_idx + 1)::TEXT, 3, '0')
      );
    END LOOP;
  END LOOP;

  -- ==========================================================
  -- (d) limbah_transactions: Penjahit setor limbah kain
  --     22 penjahit × 12 bulan (mulai bulan ke-4) = 264 baris
  --
  --     Formula berat:
  --       GREATEST(1, floor(perca_3_bulan_lalu × 15 / 100))
  --       = 1 – 2 KG per setor (sangat kecil, aman untuk stock)
  --
  --     Trigger trg_limbah_reduce_stock → kurangi total_stock saja
  --     (tanpa menambah upah)
  -- ==========================================================
  FOR v_month_num IN 3..14 LOOP
    v_month_date := DATE '2025-01-01' + (v_month_num * INTERVAL '1 month');

    FOR v_tailor_idx IN 0..21 LOOP
      -- Referensi perca yang diterima 3 bulan lalu
      v_perca_ref := 8 + ((v_tailor_idx * 3 + (v_month_num - 3) * 7) % 10);
      v_weight    := GREATEST(1, FLOOR(v_perca_ref * 15 / 100));

      INSERT INTO public.limbah_transactions
        (id, id_tailor, date_entry, weight_limbah, delivery_proof)
      VALUES (
        gen_random_uuid(),
        v_tailor_ids[v_tailor_idx + 1],
        v_month_date + (v_tailor_idx % 20),
        v_weight,
        'LMB/' || TO_CHAR(v_month_date, 'YYYYMM') || '/' ||
          LPAD((v_tailor_idx + 1)::TEXT, 3, '0')
      );
    END LOOP;
  END LOOP;

  -- ==========================================================
  -- (e) salary: Catatan gaji historis penjahit
  --     Dicatat setiap 2 bulan (bulan genap: 0,2,4,...,14)
  --     = 8 bulan × 22 penjahit = 176 baris
  --
  --     Formula saldo:
  --       100.000 + ((tailor_idx × 20.000 + bulan × 15.000) % 500.000)
  --       = Rp 100.000 – Rp 600.000 per entri
  -- ==========================================================
  FOR v_month_num IN 0..14 LOOP
    IF v_month_num % 2 = 0 THEN
      v_month_date := DATE '2025-01-01' + (v_month_num * INTERVAL '1 month');

      FOR v_tailor_idx IN 0..21 LOOP
        INSERT INTO public.salary (id_tailor, balance, date_entry)
        VALUES (
          v_tailor_ids[v_tailor_idx + 1],
          100000 + ((v_tailor_idx * 20000 + v_month_num * 15000) % 500000),
          v_month_date + (v_tailor_idx % 25)
        );
      END LOOP;
    END IF;
  END LOOP;

  -- ==========================================================
  -- (f) salary_withdrawals: Penarikan gaji penjahit
  --     Mulai bulan ke-5 (index 4), tidak setiap bulan.
  --     Kondisi skip: (tailor_idx + bulan) % 3 = 0 → ±1/3 di-skip
  --     ≈ 11 bulan × 22 penjahit × 2/3 ≈ 161 baris
  --
  --     Formula nominal:
  --       20.000 + ((tailor_idx × 3.000 + bulan × 5.000) % 40.000)
  --       = Rp 20.000 – Rp 60.000 per penarikan
  -- ==========================================================
  FOR v_month_num IN 4..14 LOOP
    v_month_date := DATE '2025-01-01' + (v_month_num * INTERVAL '1 month');

    FOR v_tailor_idx IN 0..21 LOOP
      IF (v_tailor_idx + v_month_num) % 3 != 0 THEN
        INSERT INTO public.salary_withdrawals (id_tailor, amount, date_entry)
        VALUES (
          v_tailor_ids[v_tailor_idx + 1],
          20000 + ((v_tailor_idx * 3000 + v_month_num * 5000) % 40000),
          v_month_date + (v_tailor_idx % 25)
        );
      END IF;
    END LOOP;
  END LOOP;

  -- ==========================================================
  -- (g) majun_stock: Stok lap majun di gudang
  --     Mulai bulan ke-3 (index 2), tidak setiap penjahit setiap bulan.
  --     Kondisi skip: (tailor_idx + bulan) % 4 = 0 → ±1/4 di-skip
  --     ≈ 13 bulan × 22 penjahit × 3/4 ≈ 215 baris
  --
  --     Formula berat:
  --       3 + ((tailor_idx × 3 + bulan × 5) % 15) = 3 – 17 KG
  -- ==========================================================
  FOR v_month_num IN 2..14 LOOP
    v_month_date := DATE '2025-01-01' + (v_month_num * INTERVAL '1 month');

    FOR v_tailor_idx IN 0..21 LOOP
      IF (v_tailor_idx + v_month_num) % 4 != 0 THEN
        INSERT INTO public.majun_stock (id, id_tailor, date_entry, weight)
        VALUES (
          gen_random_uuid(),
          v_tailor_ids[v_tailor_idx + 1],
          v_month_date + (v_tailor_idx % 25),
          3 + ((v_tailor_idx * 3 + v_month_num * 5) % 15)
        );
      END IF;
    END LOOP;
  END LOOP;

END $$;

-- ============================================================
-- LANGKAH 6b: Aktifkan kembali trigger WA enqueue
-- ============================================================
DO $$
DECLARE
  v_trigger RECORD;
BEGIN
  FOR v_trigger IN
    SELECT
      n.nspname AS schema_name,
      c.relname AS table_name,
      t.tgname  AS trigger_name
    FROM pg_trigger t
    JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE NOT t.tgisinternal
      AND n.nspname = 'public'
      AND t.tgname LIKE 'trg_enqueue_wa_%'
  LOOP
    EXECUTE format(
      'ALTER TABLE %I.%I ENABLE TRIGGER %I',
      v_trigger.schema_name,
      v_trigger.table_name,
      v_trigger.trigger_name
    );
  END LOOP;
END $$;

-- ============================================================
-- LANGKAH 7: Bersihkan antrian WA yang terbentuk oleh trigger
-- Trigger pada majun_transactions, percas_stock, dll. otomatis
-- memasukkan notifikasi ke wa_notification_queue selama seeding.
-- Baris berikut membersihkannya agar tidak mengganggu dev.
-- ============================================================
TRUNCATE TABLE
  public.wa_notification_logs,
  public.wa_notification_queue
RESTART IDENTITY CASCADE;

COMMIT;

-- ============================================================
-- RINGKASAN DATA YANG DI-SEED
-- ============================================================
-- Jalankan query berikut untuk verifikasi setelah seed:
--
--   SELECT 'factories'          AS tabel, COUNT(*) AS jumlah FROM public.factories
--   UNION ALL
--   SELECT 'tailors',                     COUNT(*) FROM public.tailors
--   UNION ALL
--   SELECT 'percas_stock',                COUNT(*) FROM public.percas_stock
--   UNION ALL
--   SELECT 'percas_stock total KG',       SUM(weight) FROM public.percas_stock
--   UNION ALL
--   SELECT 'perca_transactions',          COUNT(*) FROM public.perca_transactions
--   UNION ALL
--   SELECT 'majun_transactions',          COUNT(*) FROM public.majun_transactions
--   UNION ALL
--   SELECT 'limbah_transactions',         COUNT(*) FROM public.limbah_transactions
--   UNION ALL
--   SELECT 'salary',                      COUNT(*) FROM public.salary
--   UNION ALL
--   SELECT 'salary_withdrawals',          COUNT(*) FROM public.salary_withdrawals
--   UNION ALL
--   SELECT 'majun_stock',                 COUNT(*) FROM public.majun_stock
--   UNION ALL
--   SELECT 'expedition_partners',         COUNT(*) FROM public.expedition_partners;
--
-- Verifikasi stok per penjahit:
--   SELECT name, total_stock, balance FROM public.tailors ORDER BY name;
-- ============================================================
