# Activity Diagram — Tambah Stok Perca

**Aktor:** Driver  
**Deskripsi:** Driver menginput data pengambilan perca dari pabrik. Setelah data dan foto bukti tersimpan, trigger database secara otomatis mengantrekan notifikasi WhatsApp ke Manager.

```mermaid
flowchart TD
    Start(["●  Mulai"])
    OpenForm["Buka form Tambah Stok Perca"]
    LoadFactories["Muat daftar Pabrik dari DB\n(tabel factories)"]
    FillForm["Isi form:\n- Pilih Pabrik\n- Tanggal masuk\n- Jenis perca\n- Berat (kg)\n- Kode karung\n- Status"]
    TakePhoto["Ambil / pilih\nfoto bukti pengambilan"]
    Validate{"Semua field\nvalid?"}
    ShowValidationError["Tampilkan pesan\nvalidasi error"]
    CompressImage["Compress gambar\n(ImageCompressor)"]
    UploadImage["Upload gambar ke\nSupabase Storage\n(bucket: majunkita/stok_perca/)"]
    UploadSuccess{"Upload\nberhasil?"}
    ShowUploadError["Tampilkan pesan\nerror upload"]
    SingleOrBulk{"Satu item\natau banyak?"}
    InsertSingle["INSERT ke percas_stock\n(saveStockToDatabase)"]
    InsertBulk["RPC: process_bulk_percas_stock()\n(bulk insert — 1 trigger WA)"]
    DBTrigger["⚡ DB Trigger AFTER INSERT\n→ INSERT ke wa_notification_queue\n(status: pending, recipient: Manager)"]
    ShowSuccess["Tampilkan pesan berhasil\nReset form"]
    End(["◉  Selesai"])

    Start --> OpenForm
    OpenForm --> LoadFactories
    LoadFactories --> FillForm
    FillForm --> TakePhoto
    TakePhoto --> Validate
    Validate -->|Tidak| ShowValidationError
    ShowValidationError --> FillForm
    Validate -->|Ya| CompressImage
    CompressImage --> UploadImage
    UploadImage --> UploadSuccess
    UploadSuccess -->|Tidak| ShowUploadError
    ShowUploadError --> TakePhoto
    UploadSuccess -->|Ya| SingleOrBulk
    SingleOrBulk -->|1 item| InsertSingle
    SingleOrBulk -->|banyak| InsertBulk
    InsertSingle --> DBTrigger
    InsertBulk --> DBTrigger
    DBTrigger --> ShowSuccess
    ShowSuccess --> End
```

## Langkah-langkah

| # | Langkah | Keterangan |
|---|---|---|
| 1 | Buka form | Driver membuka halaman Tambah Stok Perca |
| 2 | Muat pabrik | Dropdown pabrik diambil dari tabel `factories` |
| 3 | Isi form | Pilih pabrik, jenis perca, berat, kode karung, tanggal, status |
| 4 | Foto bukti | Ambil/pilih foto pengambilan perca |
| 5 | Validasi | Semua field wajib harus terisi |
| 6 | Compress & upload | Gambar dikompres lalu diupload ke Supabase Storage |
| 7 | Insert DB | Data disimpan ke tabel `percas_stock` (single) atau via RPC bulk |
| 8 | Trigger WA | DB trigger mengantrekan notifikasi ke `wa_notification_queue` |
