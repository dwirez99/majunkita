# Activity Diagram — Setor Limbah

**Aktor:** Admin  
**Deskripsi:** Admin mencatat penyerahan limbah dari penjahit. DB trigger memperbarui stok penjahit tanpa menambah upah (limbah tidak dihargai).

```mermaid
flowchart TD
    Start(["●  Mulai"])
    OpenScreen["Buka halaman Setor Limbah"]
    LoadTailors["Muat daftar Penjahit\n(tabel tailors)"]
    SelectTailor["Pilih Penjahit"]
    InputWeight["Input berat limbah (kg)"]
    TakePhoto["Ambil / pilih foto bukti\n(opsional)"]
    Validate{"Penjahit & berat > 0?"}
    ShowValidationError["Tampilkan pesan\nvalidasi error"]
    HasPhoto{"Ada foto\nbukti?"}
    CompressUpload["Compress & upload gambar ke\nSupabase Storage\n(bucket: majunkita/limbah_photos/)"]
    UploadSuccess{"Upload\nberhasil?"}
    ShowUploadError["Tampilkan pesan\nerror upload"]
    InsertLimbah["INSERT ke tabel limbah_transactions\n(id_tailor, weight_limbah, staff_id,\ndelivery_proof atau null)"]
    DBTrigger["⚡ DB Trigger AFTER INSERT\n→ UPDATE tailors:\ntotal_stock -= weight_limbah\n(tanpa perubahan balance)"]
    ShowSuccess["Tampilkan pesan berhasil\nStok penjahit diperbarui"]
    End(["◉  Selesai"])

    Start --> OpenScreen
    OpenScreen --> LoadTailors
    LoadTailors --> SelectTailor
    SelectTailor --> InputWeight
    InputWeight --> TakePhoto
    TakePhoto --> Validate
    Validate -->|Tidak| ShowValidationError
    ShowValidationError --> InputWeight
    Validate -->|Ya| HasPhoto
    HasPhoto -->|Ya| CompressUpload
    CompressUpload --> UploadSuccess
    UploadSuccess -->|Tidak| ShowUploadError
    ShowUploadError --> TakePhoto
    UploadSuccess -->|Ya| InsertLimbah
    HasPhoto -->|Tidak| InsertLimbah
    InsertLimbah --> DBTrigger
    DBTrigger --> ShowSuccess
    ShowSuccess --> End
```

## Langkah-langkah

| # | Langkah | Keterangan |
|---|---|---|
| 1 | Pilih penjahit | Admin memilih penjahit dari dropdown |
| 2 | Input berat | Berat limbah dalam kg |
| 3 | Foto (opsional) | Foto bukti bersifat opsional untuk setor limbah |
| 4 | Insert DB | Transaksi disimpan ke tabel `limbah_transactions` |
| 5 | AFTER INSERT trigger | DB mengurangi `total_stock` penjahit tanpa mengubah `balance` |

> **Catatan:** Berbeda dengan Setor Majun, setor limbah **tidak menghasilkan upah** dan **tidak mengantrekan notifikasi WA**.
