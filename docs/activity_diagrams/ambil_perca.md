# Activity Diagram — Ambil Perca (Transaksi Perca)

**Aktor:** Admin  
**Deskripsi:** Admin mencatat pengambilan perca oleh penjahit. DB trigger mengelompokkan notifikasi per batch menggunakan debounce 2 detik dan advisory lock untuk mencegah duplikat notifikasi WA ke Manager.

```mermaid
flowchart TD
    Start(["●  Mulai"])
    OpenScreen["Buka halaman Transaksi Perca"]
    LoadData["Muat data:\n- Daftar Penjahit\n- Riwayat transaksi perca"]
    ChooseAction{"Aksi\npengguna?"}

    %% Add Transaction
    OpenAddForm["Buka form Tambah Transaksi Perca"]
    FillForm["Isi form:\n- Pilih Penjahit\n- Jenis perca\n- Berat (kg)\n- Tanggal"]
    Validate{"Semua field valid?"}
    ShowValidationError["Tampilkan pesan\nvalidasi error"]
    InsertTransaction["INSERT ke tabel perca_transactions\n(id_tailor, perca_type, weight, date_entry)"]
    DBTriggerUpdate["⚡ DB Trigger AFTER INSERT\n→ UPDATE tailors:\ntotal_stock += weight\n(stok perca bertambah)"]
    DBTriggerWA["⚡ DB Trigger AFTER INSERT\n→ Debounce 2 detik + advisory lock\n→ Kelompokkan per batch\n→ INSERT ke wa_notification_queue\n(status: pending, recipient: Manager)"]
    ShowSuccess["Tampilkan pesan berhasil\nRefresh riwayat"]

    %% View History
    ViewHistory["Tampilkan riwayat transaksi perca\n(filter per penjahit / tanggal)"]

    End(["◉  Selesai"])

    Start --> OpenScreen
    OpenScreen --> LoadData
    LoadData --> ChooseAction

    ChooseAction -->|"Tambah"| OpenAddForm
    OpenAddForm --> FillForm
    FillForm --> Validate
    Validate -->|Tidak| ShowValidationError
    ShowValidationError --> FillForm
    Validate -->|Ya| InsertTransaction
    InsertTransaction --> DBTriggerUpdate
    DBTriggerUpdate --> DBTriggerWA
    DBTriggerWA --> ShowSuccess
    ShowSuccess --> LoadData

    ChooseAction -->|"Lihat riwayat"| ViewHistory
    ViewHistory --> End

    LoadData --> End
```

## Langkah-langkah

| # | Langkah | Keterangan |
|---|---|---|
| 1 | Pilih penjahit | Dari dropdown yang memuat semua penjahit aktif |
| 2 | Isi detail | Jenis perca, berat, tanggal pengambilan |
| 3 | Validasi | Semua field wajib terisi |
| 4 | Insert DB | Transaksi disimpan ke tabel `perca_transactions` |
| 5 | Update stok | Trigger menambah `total_stock` penjahit di tabel `tailors` |
| 6 | Notif WA | Trigger mengantrekan notifikasi ke Manager dengan debounce & advisory lock (mencegah duplikat jika banyak baris masuk berurutan) |
