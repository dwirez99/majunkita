# Activity Diagram — Setor Majun

**Aktor:** Admin  
**Deskripsi:** Admin mencatat penyerahan majun dari penjahit ke gudang. DB trigger secara otomatis menghitung upah (berat × harga/kg), memperbarui saldo dan stok penjahit, serta mengantrekan notifikasi WhatsApp ke penjahit.

```mermaid
flowchart TD
    Start(["●  Mulai"])
    OpenScreen["Buka halaman Kelola Majun"]
    LoadTailors["Muat daftar Penjahit\n(tabel tailors)"]
    SelectTailor["Pilih Penjahit"]
    LoadPrice["Muat harga majun per kg\n(app_settings: majun_price_per_kg)"]
    InputWeight["Input berat majun (kg)"]
    TakePhoto["Ambil / pilih foto\nbukti setor majun (wajib)"]
    Validate{"Semua field valid?\n(penjahit, berat > 0, foto)"}
    ShowValidationError["Tampilkan pesan\nvalidasi error"]
    CompressImage["Compress gambar\n(ImageCompressor)"]
    UploadImage["Upload gambar ke\nSupabase Storage\n(bucket: majunkita/majun_photos/)"]
    UploadSuccess{"Upload\nberhasil?"}
    ShowUploadError["Tampilkan pesan\nerror upload"]
    InsertMajun["INSERT ke tabel majun_transactions\n(id_tailor, weight_majun, staff_id, delivery_proof)"]
    DBTriggerBefore["⚡ DB Trigger BEFORE INSERT\n→ Auto-hitung:\nearned_wage = weight_majun × price_per_kg"]
    DBTriggerAfter["⚡ DB Trigger AFTER INSERT\n→ UPDATE tailors:\ntotal_stock -= weight_majun\nbalance += earned_wage\n→ INSERT ke wa_notification_queue\n(status: pending, recipient: Penjahit, dengan foto bukti)"]
    ShowResult["Tampilkan hasil:\nUpah yang diperoleh penjahit\nSaldo baru"]
    End(["◉  Selesai"])

    Start --> OpenScreen
    OpenScreen --> LoadTailors
    LoadTailors --> SelectTailor
    SelectTailor --> LoadPrice
    LoadPrice --> InputWeight
    InputWeight --> TakePhoto
    TakePhoto --> Validate
    Validate -->|Tidak| ShowValidationError
    ShowValidationError --> InputWeight
    Validate -->|Ya| CompressImage
    CompressImage --> UploadImage
    UploadImage --> UploadSuccess
    UploadSuccess -->|Tidak| ShowUploadError
    ShowUploadError --> TakePhoto
    UploadSuccess -->|Ya| InsertMajun
    InsertMajun --> DBTriggerBefore
    DBTriggerBefore --> DBTriggerAfter
    DBTriggerAfter --> ShowResult
    ShowResult --> End
```

## Langkah-langkah

| # | Langkah | Keterangan |
|---|---|---|
| 1 | Pilih penjahit | Admin memilih penjahit dari dropdown |
| 2 | Muat harga | Harga per kg diambil dari `app_settings` |
| 3 | Input berat | Admin memasukkan berat majun yang disetor |
| 4 | Foto bukti | Wajib mengambil/memilih foto bukti setor |
| 5 | Compress & upload | Foto dikompres lalu diupload ke Storage |
| 6 | BEFORE INSERT trigger | DB menghitung `earned_wage = weight_majun × price_per_kg` secara otomatis |
| 7 | AFTER INSERT trigger | DB memperbarui `total_stock` dan `balance` penjahit, lalu enqueue notif WA |
| 8 | Tampilkan hasil | Upah dan saldo baru ditampilkan di layar |
