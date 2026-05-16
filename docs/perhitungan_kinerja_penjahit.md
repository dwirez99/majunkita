# Panduan Perhitungan Kinerja Penjahit

Dokumen ini menjelaskan secara rinci bagaimana sistem **MajunKita** menghitung dan menilai kinerja dari masing-masing penjahit berdasarkan data bahan perca yang diambil dan lap majun yang disetor.

---

## 1. Sisa Perca (Stok Bahan di Rumah)

**Definisi:**  
Sisa Perca adalah perkiraan berat bahan kain/kaos yang saat ini masih berada di tangan penjahit dan belum dikembalikan ke gudang (baik sebagai majun maupun limbah).

**Rumus Perhitungan:**
```text
Sisa Perca = Total Perca Diambil - Total Majun Disetor - Total Limbah Disetor
```

**Penjelasan:**
- **Total Perca Diambil:** Semua bahan mentah yang pernah didistribusikan kepada penjahit.
- **Total Majun Disetor:** Lap majun jadi yang sudah berhasil dijahit dan dikembalikan.
- **Total Limbah Disetor:** Sisa potongan kain yang tidak bisa digunakan (limbah) dan diserahkan kembali.

*Catatan:* Jika terjadi penyusutan/kehilangan bahan (*shrinkage*) yang tidak disetorkan sebagai limbah, berat tersebut akan tetap terhitung dan mengendap di dalam **Sisa Perca**.

---

## 2. Kualitas Kerja Penjahit (Rasio Efisiensi / Reff)

**Definisi:**  
Ini adalah metrik yang menunjukkan tingkat efisiensi penjahit dalam menyulap bahan mentah (perca) menjadi barang jadi (majun). Nilai ini direpresentasikan dalam persentase (0.0 hingga 1.0).

**Rumus Perhitungan:**
```text
Reff = Total Majun Disetor / Total Perca Diambil
```

**Penilaian (Ambang Batas / Threshold):**
Mengingat adanya sisa bahan yang masih diproses, serta potongan limbah dan penyusutan alami, nilai efisiensi (Reff) di atas **40% (0.40)** dinilai sebagai batas normal. 

Sistem mengklasifikasikannya menjadi 3 status:

| Kategori | Syarat (Nilai Reff) | Keterangan | Indikator Warna |
| :--- | :--- | :--- | :--- |
| **Hasil Bagus** | `>= 0.55` (55% ke atas) | Sangat efisien, minim limbah, dan perputaran cepat. | 🟢 Hijau |
| **Hasil Sedang** | `0.40 - 0.54` (40% - 54%) | Rata-rata standar penjahit pada umumnya. | 🟠 Kuning/Amber |
| **Hasil Rendah** | `< 0.40` (Di bawah 40%) | Banyak bahan terbuang/tertahan lama belum disetor. | 🔴 Merah |

**Ilustrasi Hasil (Yield per 50 Kg):**
Untuk mempermudah pemahaman pengguna (terutama lansia/non-teknis), sistem menerjemahkan rasio ini ke dalam kalimat sederhana:
> *"Dari 50 Kg perca, biasanya menjadi sekitar **[Reff × 50] Kg** majun jadi."*

---

## 3. Perkiraan Hasil Nanti (Prediksi Majun)

**Definisi:**  
Sistem menggunakan data historis (Kualitas Kerja / Reff) dari penjahit tersebut untuk memprediksi berapa banyak majun yang akan dihasilkan dari bahan yang saat ini masih mereka pegang (Sisa Perca).

**Rumus Perhitungan:**
```text
Perkiraan Majun = Sisa Perca × Reff
```

**Contoh Kasus:**
- Ibu Siti memiliki **Sisa Perca** sebanyak `60 Kg`.
- Kinerja historis (Reff) Ibu Siti adalah `0.50` (Hasil Sedang).
- **Perkiraan Hasil Nanti:** `60 Kg × 0.50 = 30 Kg`.

Sistem akan menampilkan di layar:
> *"Sisa bahan saat ini kira-kira bisa menghasilkan sekitar **30 Kg** majun."*

---

## Kesimpulan
Perhitungan ini dibuat sangat dinamis. Semakin rajin penjahit menyetorkan majun jadi (tanpa menimbun sisa perca berlama-lama), maka nilai Kualitas Kerja (Reff) mereka akan semakin tinggi, dan perkiraan hasil majun untuk periode berikutnya akan semakin akurat.
