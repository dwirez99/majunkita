# Use Case Diagram — Driver

Diagram ini menggambarkan use case untuk peran **Driver** dalam sistem Majunkita.

```mermaid
flowchart LR
    Driver(["🚚 Driver"])

    subgraph Sistem["🖥️ Sistem Majunkita"]
        %% Shared
        UC_Login["Login"]
        UC_Logout["Logout"]
        UC_Profile["Lihat & Edit Profil"]
        UC_Notif["Lihat Notifikasi WA"]

        %% Driver specific
        UC_Dash["Lihat Dashboard Driver"]
        UC_AddPerca["Tambah Data Perca"]
        UC_AddExp["Tambah Expedisi Baru"]
        UC_HistExp["Lihat Riwayat Pengiriman"]
        UC_ManExp["Kelola Expedisi"]
        UC_Summary["Lihat Ringkasan Pengirimanku"]
    end

    Driver --> UC_Login
    Driver --> UC_Logout
    Driver --> UC_Profile
    Driver --> UC_Notif
    Driver --> UC_Dash
    Driver --> UC_AddPerca
    Driver --> UC_AddExp
    Driver --> UC_HistExp
    Driver --> UC_ManExp
    Driver --> UC_Summary
```

## Use Case Driver

| No | Use Case | Deskripsi |
|---|---|---|
| 1 | Login | Masuk ke sistem menggunakan akun Driver |
| 2 | Logout | Keluar dari sistem |
| 3 | Lihat & Edit Profil | Melihat dan mengubah data profil sendiri |
| 4 | Lihat Notifikasi WA | Melihat notifikasi yang dikirim via WhatsApp |
| 5 | Lihat Dashboard Driver | Melihat ringkasan data di halaman utama Driver |
| 6 | Tambah Data Perca | Menginput data pengambilan perca dari pabrik |
| 7 | Tambah Expedisi Baru | Membuat catatan pengiriman baru |
| 8 | Lihat Riwayat Pengiriman | Melihat daftar pengiriman yang pernah dilakukan |
| 9 | Kelola Expedisi | Mengubah atau memperbarui data expedisi milik sendiri |
| 10 | Lihat Ringkasan Pengirimanku | Melihat statistik pengiriman yang telah dilakukan |
