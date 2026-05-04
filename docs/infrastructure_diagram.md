# Infrastructure Diagram — Majunkita

Diagram ini menggambarkan alur infrastruktur dari **Flutter App** (frontend) ke **Supabase** (backend) hingga **WA Gateway** (WhatsApp API).

---

## Diagram Infrastruktur

```mermaid
flowchart TD
    %% ── Actors / Clients ─────────────────────────────────────────
    subgraph Clients["📱 Client Layer"]
        Admin(["👤 Admin\n(Flutter App)"])
        Driver(["🚚 Driver\n(Flutter App)"])
        Manager(["👔 Manager\n(Flutter App)"])
    end

    %% ── Supabase Backend ─────────────────────────────────────────
    subgraph Supabase["☁️ Supabase (Backend)"]
        Auth["🔐 Auth\n(JWT, Email/Password)"]
        PostgREST["🔌 PostgREST API\n(REST → PostgreSQL)"]
        Storage["🗄️ Storage\n(Proof images, photos)"]

        subgraph DB["🐘 PostgreSQL Database"]
            Tables["📋 Core Tables\n(expeditions, percas_stock,\nmajun_transactions,\nperca_transactions,\nsalary_withdrawals, ...)"]
            Queue["📬 wa_notification_queue\n(status: pending → processing → sent/failed)"]
            Logs["📝 wa_notification_logs"]
            Triggers["⚡ DB Triggers\n(AFTER INSERT → enqueue WA notification)"]
            Users["👥 users / profiles\n(role: admin | driver | manager)"]
        end

        subgraph EdgeFunctions["⚙️ Edge Functions (Deno)"]
            CreateUser["create-user"]
            UpdateUser["update-user"]
            DeleteUser["delete-user"]
            WaWorker["process-wa-notification-queue\n(queue worker, scheduled)"]
        end

        Scheduler["🕐 pg_cron / Scheduler\n(periodic HTTP call)"]
    end

    %% ── WA Gateway ───────────────────────────────────────────────
    subgraph WALayer["📡 WA Gateway Layer"]
        Cloudflare["🌐 Cloudflare Tunnel\n(optional — local device)"]

        subgraph WAServer["🖥️ go-whatsapp-web-multidevice\n(VPS or RPi / Android Box)"]
            WAGateway["WA Gateway\n(Docker + nginx + Swagger)"]
            WAEndpoints["Endpoints:\nGET  /app/status\nPOST /send/message\nPOST /send/image"]
        end
    end

    %% ── WhatsApp ─────────────────────────────────────────────────
    WA(["💬 WhatsApp\nRecipient\n(Penjahit / Manager)"])

    %% ── Connections: Client → Supabase ───────────────────────────
    Admin   -->|"HTTPS (Supabase JS SDK)"| Auth
    Driver  -->|"HTTPS (Supabase JS SDK)"| Auth
    Manager -->|"HTTPS (Supabase JS SDK)"| Auth

    Admin   -->|"REST queries (JWT)"| PostgREST
    Driver  -->|"REST queries (JWT)"| PostgREST
    Manager -->|"REST queries (JWT)"| PostgREST

    Admin   -->|"Upload proof image"| Storage
    Driver  -->|"Upload proof image"| Storage

    PostgREST --> Tables
    PostgREST --> Users

    %% ── Connections: DB internal ─────────────────────────────────
    Tables -->|"AFTER INSERT trigger"| Triggers
    Triggers -->|"INSERT pending row"| Queue

    %% ── Edge Functions: User management ─────────────────────────
    Admin   -->|"Invoke Edge Function"| CreateUser
    Admin   -->|"Invoke Edge Function"| UpdateUser
    Admin   -->|"Invoke Edge Function"| DeleteUser
    Manager -->|"Invoke Edge Function"| CreateUser
    Manager -->|"Invoke Edge Function"| UpdateUser
    Manager -->|"Invoke Edge Function"| DeleteUser
    CreateUser --> Users
    UpdateUser --> Users
    DeleteUser --> Users

    %% ── Connections: Scheduler → WA Worker ───────────────────────
    Scheduler -->|"periodic POST"| WaWorker
    WaWorker -->|"dequeue_wa_notifications()"| Queue
    WaWorker -->|"download proof image"| Storage
    WaWorker -->|"INSERT result"| Logs

    %% ── Connections: WA Worker → WA Gateway ─────────────────────
    WaWorker -->|"HTTPS + Basic Auth"| Cloudflare
    Cloudflare -->|"tunnel"| WAGateway
    WaWorker -->|"direct HTTPS\n(if VPS)"| WAGateway
    WAGateway --> WAEndpoints
    WAEndpoints -->|"WhatsApp message / image"| WA
```

---

## Penjelasan Lapisan

### 1. Client Layer — Flutter App
- Satu aplikasi Flutter untuk tiga peran: **Admin**, **Driver**, dan **Manager**.
- Berkomunikasi dengan Supabase menggunakan **Supabase Dart SDK** melalui HTTPS.
- Auth menggunakan **JWT** berbasis Email + Password yang dikelola Supabase Auth.
- Upload foto bukti pengiriman/setor ke **Supabase Storage**.

### 2. Backend — Supabase
| Komponen | Fungsi |
|---|---|
| **Auth** | Login, logout, JWT token, manajemen sesi |
| **PostgREST** | REST API otomatis dari skema PostgreSQL |
| **PostgreSQL** | Penyimpanan data utama (expedisi, perca, majun, dll.) |
| **DB Triggers** | Setelah INSERT ke tabel utama, otomatis enqueue notifikasi WA |
| **wa_notification_queue** | Antrian notifikasi dengan status & retry logic |
| **wa_notification_logs** | Log hasil pengiriman ke WA Gateway |
| **Storage** | Penyimpanan file gambar (bukti pengiriman) |
| **Edge Functions** | Manajemen user (create/update/delete) dan pemrosesan queue WA |
| **Scheduler** | Memanggil edge function `process-wa-notification-queue` secara berkala |

### 3. WA Gateway — go-whatsapp-web-multidevice
- Self-hosted di **VPS** atau **device lokal** (Raspberry Pi / Android Box).
- Jika lokal, diteruskan ke internet via **Cloudflare Tunnel**.
- Edge function memanggil gateway dengan **Basic Auth**.
- Gateway mengirim pesan ke penerima WhatsApp melalui endpoint `/send/message` (teks) atau `/send/image` (teks + foto).

### 4. Alur Notifikasi WA (End-to-End)

```
Flutter App
    │ INSERT data (expedisi / perca / majun / salary)
    ▼
PostgreSQL Core Tables
    │ AFTER INSERT trigger
    ▼
wa_notification_queue  (status: pending)
    │ pg_cron / Scheduler (periodic)
    ▼
process-wa-notification-queue  (Edge Function)
    │ GET /app/status  → health check
    │ POST /send/message  atau  POST /send/image
    ▼
go-whatsapp-web-multidevice  ←── [Cloudflare Tunnel jika lokal]
    │
    ▼
WhatsApp Penerima (Penjahit / Manager)
    │ result
    ▼
wa_notification_logs
```

### Retry & Backoff
- Jika pengiriman gagal, baris dikembalikan ke status `pending` dengan **exponential backoff** (1, 2, 4, 8 … maks 30 menit).
- Setelah `max_retries` tercapai, status menjadi `failed`.
