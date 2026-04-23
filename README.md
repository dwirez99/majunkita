# majunkita

A Flutter mobile application for managing the **majun** (textile-waste cloth) supply chain — from tailor pickup to perca fabric stock and expedition delivery — backed by Supabase.

## Modules

| Module | Description | README |
|---|---|---|
| **Authentication** | Email/password login with role-based routing | [docs](lib/features/auth/README.md) |
| **Dashboard** | Role-specific dashboards for Admin, Manager, and Driver | [docs](lib/features/Dashboard/README.md) |
| **Penjahit (Tailor)** | Record majun collection from tailors, track wages and delivery proof | [docs](lib/features/manage_tailors/README.md) |
| **Stok Perca** | Manage incoming perca fabric stock from factories | [docs](lib/features/manage_percas/README.md) |
| **Ekspedisi** | Track outbound expedition shipments | [docs](lib/features/manage_expeditions/README.md) |
| **Manajemen Majun** | Record majun & limbah setoran transactions | [docs](lib/features/manage_majun/README.md) |
| **Pabrik (Factory)** | Manage supplier factory data | [docs](lib/features/manage_factories/README.md) |
| **Kelola Partner** | Manage admin and driver accounts | [docs](lib/features/manage_partner/README.md) |
| **Notifikasi WA** | WhatsApp notification queue and status monitoring | [docs](lib/features/manage_notifications/README.md) |

## Tech Stack

- **Frontend:** Flutter (Android)
- **Backend:** [Supabase](https://supabase.com) — PostgreSQL, Row Level Security, Storage, Edge Functions
- **WhatsApp Gateway:** [dwirez99/go-whatsapp-web-multidevice](https://github.com/dwirez99/go-whatsapp-web-multidevice) — self-hosted, exposed via Cloudflare Tunnel

## Architecture

```mermaid
graph TD
    subgraph Flutter["📱 Flutter App (Android)"]
        AUTH[Authentication\nauth feature]
        DASH[Dashboard\nAdmin / Manager / Driver]
        TAILOR[Kelola Penjahit\nmanage_tailors]
        MAJUN[Majun & Limbah\nmanage_majun]
        PERCA[Stok Perca\nmanage_percas]
        EXPD[Ekspedisi\nmanage_expeditions]
        FACTORY[Pabrik\nmanage_factories]
        PARTNER[Kelola Partner\nmanage_partner]
        NOTIF[Notifikasi WA\nmanage_notifications]
    end

    subgraph Supabase["☁️ Supabase (Backend)"]
        DB[(PostgreSQL\nDatabase)]
        RLS[Row Level Security]
        STORAGE[Storage\nBucket]
        FUNC[Edge Functions\ncreate-user\nupdate-user\ndelete-user\nprocess-wa-notification-queue]
        TRIGGER[DB Triggers\n& RPCs]
    end

    subgraph WA["💬 WhatsApp Gateway"]
        WAGATEWAY[go-whatsapp-web-multidevice\nself-hosted via Docker]
        CF[Cloudflare Tunnel]
    end

    Flutter -->|Supabase Flutter SDK| Supabase
    FUNC -->|HTTP REST| CF
    CF --> WAGATEWAY
    DB --> TRIGGER
    TRIGGER -->|Enqueue messages| DB
    FUNC -->|Dequeue & send| DB
```

## Use Case Diagram

```mermaid
graph LR
    ADMIN((Admin))
    MANAGER((Manager))
    DRIVER((Driver))

    ADMIN -->|Kelola Data Penjahit| UC1[Tambah / Edit / Hapus Penjahit]
    ADMIN -->|Kelola Stok Perca| UC2[Input Perca Masuk dari Pabrik]
    ADMIN -->|Rekap Majun & Limbah| UC3[Setor Majun / Limbah Penjahit]
    ADMIN -->|Kelola Pabrik| UC4[Tambah / Edit / Hapus Pabrik]
    ADMIN -->|Monitor Notifikasi WA| UC5[Lihat & Retry Notifikasi WA]
    ADMIN -->|Dashboard Laporan| UC6[Lihat Statistik & Ringkasan]

    MANAGER -->|Kelola Partner| UC7[Tambah / Edit / Hapus Admin & Driver]
    MANAGER -->|Kelola Penjahit| UC1
    MANAGER -->|Kelola Stok Perca| UC2
    MANAGER -->|Dashboard Laporan| UC6

    DRIVER -->|Input Ekspedisi| UC8[Catat Pengiriman Keluar]
    DRIVER -->|Riwayat Ekspedisi| UC9[Lihat History Pengiriman]

    UC3 -->|Trigger Otomatis| WA[Kirim Notifikasi WA]
    UC2 -->|Trigger Otomatis| WA
    UC8 -->|Trigger Otomatis| WA
```

## Activity Diagram — Alur Setor Majun

```mermaid
flowchart TD
    A([Start]) --> B[Admin/Karyawan buka\nManage Majun]
    B --> C[Pilih Penjahit]
    C --> D[Input Berat Majun\n& Upload Bukti Foto]
    D --> E{Validasi Form}
    E -- Tidak Valid --> D
    E -- Valid --> F[Simpan ke majun_transactions]
    F --> G[DB Trigger hitung\nearned_wage otomatis]
    G --> H[Update tailors.balance\n& total_stock]
    H --> I[Enqueue WA Notification\nke wa_notification_queue]
    I --> J[Edge Function:\nprocess-wa-notification-queue]
    J --> K{WA Gateway\nTersedia?}
    K -- Ya --> L[Kirim WA ke Penjahit\n& Manager]
    K -- Tidak --> M[Retry otomatis\nmaks 5 kali]
    M --> J
    L --> N([End])
```

## Getting Started

### 1. Environment Setup

```bash
cp .env.example .env
# Fill in SUPABASE_URL and SUPABASE_ANON_KEY from your Supabase project settings
```

### 2. Apply Database Migrations

```bash
supabase db push
```

### 3. Seed Development Data (optional)

To populate the database with realistic Indonesian dummy data covering 15 months of transactions, run the seed script. See the full guide:

```
docs/seed-guide.md
```

Quick-start via Supabase CLI:

```bash
supabase db reset   # applies migrations + runs supabase/seed.sql automatically
```

Or paste `supabase/seed.sql` into the Supabase SQL Editor and click **Run**.

> ⚠️ Only run on development/staging databases — the script wipes all existing data.

### 4. Deploy Edge Functions

```bash
supabase functions deploy --project-ref <your-project-ref>
```

### 5. Run the Flutter App

```bash
flutter pub get
flutter run
```

## WhatsApp Integration

Automated WhatsApp notifications are sent to tailors and managers when transactions are recorded. See the full setup guide in:

```
docs/wa-integration-setup.md
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feat/your-feature`)
3. Commit your changes and open a Pull Request
