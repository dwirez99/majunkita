# Use Case Diagram — Manager

Diagram ini menggambarkan use case untuk peran **Manager** dalam sistem Majunkita.

```mermaid
flowchart LR
    Manager(["👔 Manager"])

    subgraph Sistem["🖥️ Sistem Majunkita"]
        %% Shared
        UC_Login["Login"]
        UC_Logout["Logout"]
        UC_Profile["Lihat & Edit Profil"]
        UC_Notif["Lihat Notifikasi WA"]

        %% Manager specific
        UC_Dash["Lihat Dashboard Manager"]
        UC_LatestExp["Lihat Pengiriman Terbaru"]
        UC_PercaHist["Lihat Riwayat Ambil/Setor Perca"]
        UC_ExpHist["Lihat Riwayat Pengiriman (Semua)"]
        UC_Partner["Manajemen Partner\n(Admin, Driver, Penjahit)"]
    end

    Manager --> UC_Login
    Manager --> UC_Logout
    Manager --> UC_Profile
    Manager --> UC_Notif
    Manager --> UC_Dash
    Manager --> UC_LatestExp
    Manager --> UC_PercaHist
    Manager --> UC_ExpHist
    Manager --> UC_Partner
```

## Use Case Manager

| No | Use Case | Deskripsi |
|---|---|---|
| 1 | Login | Masuk ke sistem menggunakan akun Manager |
| 2 | Logout | Keluar dari sistem |
| 3 | Lihat & Edit Profil | Melihat dan mengubah data profil sendiri |
| 4 | Lihat Notifikasi WA | Melihat notifikasi yang dikirim via WhatsApp |
| 5 | Lihat Dashboard Manager | Melihat ringkasan data di halaman utama Manager |
| 6 | Lihat Pengiriman Terbaru | Melihat daftar expedisi terbaru dari semua Driver |
| 7 | Lihat Riwayat Ambil/Setor Perca | Melihat riwayat pengambilan dan penyetoran perca |
| 8 | Lihat Riwayat Pengiriman (Semua) | Melihat seluruh riwayat pengiriman lintas Driver |
| 9 | Manajemen Partner | Menambah atau menonaktifkan akun Admin, Driver, dan Penjahit |

> **Catatan:** Manager memiliki kewenangan penuh atas pengelolaan akun, termasuk akun Admin.
