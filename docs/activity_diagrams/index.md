# Activity Diagrams — Majunkita

Folder ini berisi diagram aktivitas (activity diagram) untuk setiap use case utama dalam sistem **Majunkita**.  
Setiap diagram dibuat menggunakan **Mermaid flowchart** dan dapat dirender langsung di GitHub.

---

## Daftar Diagram

### 🔐 Autentikasi (Semua Peran)

| File | Deskripsi |
|---|---|
| [login.md](login.md) | Login menggunakan email atau username + password |
| [logout.md](logout.md) | Keluar dari sesi aktif |

### 🚚 Driver

| File | Deskripsi |
|---|---|
| [tambah_stok_perca.md](tambah_stok_perca.md) | Input pengambilan perca dari pabrik + upload foto bukti |
| [tambah_expedisi.md](tambah_expedisi.md) | Buat catatan pengiriman (expedisi) baru + upload bukti |

### 👤 Admin

| File | Deskripsi |
|---|---|
| [setor_majun.md](setor_majun.md) | Catat penyerahan majun dari penjahit (auto-hitung upah) |
| [setor_limbah.md](setor_limbah.md) | Catat penyerahan limbah dari penjahit (tanpa upah) |
| [ambil_perca.md](ambil_perca.md) | Catat pengambilan perca oleh penjahit |
| [kelola_penjahit.md](kelola_penjahit.md) | CRUD data penjahit (termasuk foto profil) |
| [kelola_pabrik.md](kelola_pabrik.md) | CRUD data pabrik sumber perca |
| [penarikan_upah.md](penarikan_upah.md) | Proses penarikan upah penjahit |
| [kelola_partner.md](kelola_partner.md) | CRUD akun Driver (via Edge Function) |

### 👔 Manager

| File | Deskripsi |
|---|---|
| [kelola_partner.md](kelola_partner.md) | CRUD akun Admin & Driver (via Edge Function) |

### ⚙️ Sistem (Background)

| File | Deskripsi |
|---|---|
| [notifikasi_wa.md](notifikasi_wa.md) | Queue worker WA: dequeue → health check → send → log |

---

## Alur Notifikasi WhatsApp (Ringkasan)

Setiap aktivitas yang memicu notifikasi WA mengikuti pola yang sama:

```
Aksi Pengguna (Flutter App)
        │ INSERT / UPDATE
        ▼
   Tabel PostgreSQL
        │ ⚡ DB Trigger AFTER INSERT
        ▼
wa_notification_queue  (status: pending)
        │ pg_cron / Scheduler (berkala)
        ▼
process-wa-notification-queue  (Edge Function)
        │ HTTPS + Basic Auth
        ▼
go-whatsapp-web-multidevice
        │
        ▼
  Penerima WhatsApp
        │ result
        ▼
wa_notification_logs
```

Lihat [notifikasi_wa.md](notifikasi_wa.md) untuk diagram lengkap beserta retry & backoff logic.
