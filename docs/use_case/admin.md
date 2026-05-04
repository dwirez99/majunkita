# Use Case Diagram — Admin

Diagram ini menggambarkan use case untuk peran **Admin** dalam sistem Majunkita.

```mermaid
flowchart LR
    Admin(["👤 Admin"])

    subgraph Sistem["🖥️ Sistem Majunkita"]
        %% Shared
        UC_Login["Login"]
        UC_Logout["Logout"]
        UC_Profile["Lihat & Edit Profil"]
        UC_Notif["Lihat Notifikasi WA"]

        %% Admin specific
        UC_Dash["Lihat Dashboard Admin"]
        UC_Perca["Kelola Stok Perca"]
        UC_Majun["Kelola Stok Majun"]
        UC_Penjahit["Kelola Penjahit"]
        UC_Pabrik["Kelola Pabrik"]
        UC_Exp["Kelola Pengiriman (Expedisi)"]
        UC_Summary["Lihat Ringkasan\n(Perca, Majun, Expedisi, Penjahit, Limbah)"]
        UC_Partner["Kelola Partner Driver & Penjahit"]
    end

    Admin --> UC_Login
    Admin --> UC_Logout
    Admin --> UC_Profile
    Admin --> UC_Notif
    Admin --> UC_Dash
    Admin --> UC_Perca
    Admin --> UC_Majun
    Admin --> UC_Penjahit
    Admin --> UC_Pabrik
    Admin --> UC_Exp
    Admin --> UC_Summary
    Admin --> UC_Partner
```

## Use Case Admin

| No | Use Case | Deskripsi |
|---|---|---|
| 1 | Login | Masuk ke sistem menggunakan akun Admin |
| 2 | Logout | Keluar dari sistem |
| 3 | Lihat & Edit Profil | Melihat dan mengubah data profil sendiri |
| 4 | Lihat Notifikasi WA | Melihat notifikasi yang dikirim via WhatsApp |
| 5 | Lihat Dashboard Admin | Melihat ringkasan data di halaman utama Admin |
| 6 | Kelola Stok Perca | Menambah, mengubah, dan menghapus data stok perca |
| 7 | Kelola Stok Majun | Menambah, mengubah, dan menghapus data stok majun |
| 8 | Kelola Penjahit | Mengelola data penjahit |
| 9 | Kelola Pabrik | Mengelola data pabrik |
| 10 | Kelola Pengiriman (Expedisi) | Mengelola data pengiriman/expedisi |
| 11 | Lihat Ringkasan | Melihat ringkasan Perca, Majun, Expedisi, Penjahit, dan Limbah |
| 12 | Kelola Partner Driver & Penjahit | Menambah atau menonaktifkan akun Driver dan Penjahit |

> **Catatan:** Admin tidak dapat mengelola sesama Admin. Pengelolaan akun Admin hanya dapat dilakukan oleh Manager.
