# Activity Diagram — Tambah Expedisi

**Aktor:** Driver  
**Deskripsi:** Driver membuat catatan pengiriman (expedisi) baru. Foto bukti pengiriman wajib diupload. Setelah data tersimpan, DB trigger mengantrekan notifikasi WhatsApp ke Manager.

```mermaid
flowchart TD
    Start(["●  Mulai"])
    OpenForm["Buka form Tambah Expedisi"]
    LoadData["Muat data pendukung:\n- Daftar Mitra Expedisi\n- Stok majun tersedia (RPC)\n- Berat per karung (app_settings)"]
    FillForm["Isi form:\n- Tanggal expedisi\n- Tujuan\n- Mitra Expedisi\n- Jumlah karung\n- Total berat (auto-hitung)"]
    TakePhoto["Ambil / pilih foto\nbukti pengiriman (wajib)"]
    Validate{"Semua field valid?\n(termasuk foto)"}
    ShowValidationError["Tampilkan pesan\nvalidasi error"]
    CheckStock{"Stok majun\ncukup?"]
    ShowStockError["Tampilkan pesan:\n'Stok tidak mencukupi'"]
    CompressImage["Compress gambar\n(ImageCompressor)"]
    UploadImage["Upload gambar ke\nSupabase Storage\n(bucket: proof_of_deliveries/)"]
    UploadSuccess{"Upload\nberhasil?"}
    ShowUploadError["Tampilkan pesan\nerror upload"]
    InsertExpedition["INSERT ke tabel expeditions\n(dengan URL bukti pengiriman)"]
    DBTrigger["⚡ DB Trigger AFTER INSERT\n→ INSERT ke wa_notification_queue\n(status: pending, recipient: Manager\n termasuk URL foto bukti)"]
    ShowSuccess["Tampilkan pesan berhasil\nKembali ke daftar expedisi"]
    End(["◉  Selesai"])

    Start --> OpenForm
    OpenForm --> LoadData
    LoadData --> FillForm
    FillForm --> TakePhoto
    TakePhoto --> Validate
    Validate -->|Tidak| ShowValidationError
    ShowValidationError --> FillForm
    Validate -->|Ya| CheckStock
    CheckStock -->|Tidak| ShowStockError
    ShowStockError --> FillForm
    CheckStock -->|Ya| CompressImage
    CompressImage --> UploadImage
    UploadImage --> UploadSuccess
    UploadSuccess -->|Tidak| ShowUploadError
    ShowUploadError --> TakePhoto
    UploadSuccess -->|Ya| InsertExpedition
    InsertExpedition --> DBTrigger
    DBTrigger --> ShowSuccess
    ShowSuccess --> End
```

## Langkah-langkah

| # | Langkah | Keterangan |
|---|---|---|
| 1 | Buka form | Driver membuka halaman Tambah Expedisi |
| 2 | Muat data | Mitra expedisi, stok majun tersedia, dan berat per karung dimuat |
| 3 | Isi form | Tujuan, tanggal, mitra, jumlah karung; berat total dihitung otomatis |
| 4 | Foto bukti | Wajib mengambil/memilih foto bukti pengiriman |
| 5 | Validasi | Field wajib terisi; stok majun harus mencukupi total berat |
| 6 | Compress & upload | Foto dikompres lalu diupload ke bucket `proof_of_deliveries` |
| 7 | Insert DB | Data expedisi disimpan ke tabel `expeditions` dengan URL foto |
| 8 | Trigger WA | DB trigger mengantrekan notifikasi ke `wa_notification_queue` (termasuk URL foto) |
