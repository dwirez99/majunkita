# Activity Diagram — Penarikan Upah Penjahit

**Aktor:** Admin  
**Deskripsi:** Admin memproses permintaan penarikan upah dari penjahit. Saldo penjahit dikurangi sebesar jumlah penarikan. DB trigger mengantrekan notifikasi WhatsApp ke penjahit yang bersangkutan.

```mermaid
flowchart TD
    Start(["●  Mulai"])
    OpenTailorDetail["Buka detail penjahit\natau halaman Salary"]
    ViewBalance["Tampilkan saldo upah\n(balance) penjahit saat ini"]
    ClickWithdraw["Klik tombol Tarik Upah"]
    OpenWithdrawDialog["Buka dialog Penarikan Upah"]
    InputAmount["Input jumlah penarikan (Rp)"]
    InputDate["Pilih tanggal penarikan"]
    Validate{"Jumlah > 0 &\ntidak melebihi saldo?"}
    ShowValidationError["Tampilkan pesan:\n'Jumlah melebihi saldo' atau\n'Jumlah harus lebih dari 0'"]
    InsertWithdrawal["INSERT ke tabel salary_withdrawals\n(id_tailor, amount, date_entry)"]
    UpdateBalance["UPDATE tabel tailors:\nbalance -= amount"]
    DBTrigger["⚡ DB Trigger AFTER INSERT\n→ INSERT ke wa_notification_queue\n(status: pending, recipient: Penjahit\npesan: 'Upah Rp X telah ditarik')"]
    ShowSuccess["Tampilkan pesan berhasil\nSaldo baru ditampilkan"]
    End(["◉  Selesai"])

    Start --> OpenTailorDetail
    OpenTailorDetail --> ViewBalance
    ViewBalance --> ClickWithdraw
    ClickWithdraw --> OpenWithdrawDialog
    OpenWithdrawDialog --> InputAmount
    InputAmount --> InputDate
    InputDate --> Validate
    Validate -->|Tidak| ShowValidationError
    ShowValidationError --> InputAmount
    Validate -->|Ya| InsertWithdrawal
    InsertWithdrawal --> UpdateBalance
    UpdateBalance --> DBTrigger
    DBTrigger --> ShowSuccess
    ShowSuccess --> End
```

## Langkah-langkah

| # | Langkah | Keterangan |
|---|---|---|
| 1 | Buka detail penjahit | Admin memilih penjahit dari daftar |
| 2 | Lihat saldo | Saldo upah yang tersedia (`balance`) ditampilkan |
| 3 | Input penarikan | Jumlah dan tanggal penarikan dimasukkan |
| 4 | Validasi | Jumlah harus > 0 dan ≤ saldo yang tersedia |
| 5 | Insert withdrawal | Transaksi disimpan ke tabel `salary_withdrawals` |
| 6 | Update saldo | `balance` penjahit dikurangi sebesar jumlah penarikan |
| 7 | Notifikasi WA | DB trigger mengantrekan notif WA ke penjahit sebagai konfirmasi penarikan |
