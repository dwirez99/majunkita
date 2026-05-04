# Activity Diagram — Proses Notifikasi WhatsApp (Queue Worker)

**Aktor:** Sistem (terjadwal otomatis via pg_cron)  
**Deskripsi:** Supabase Edge Function `process-wa-notification-queue` dijalankan secara berkala oleh scheduler. Edge function mengambil antrian notifikasi pending, memeriksa status gateway WA, lalu mengirimkan pesan teks atau gambar ke penerima WhatsApp. Setiap hasil dicatat di tabel log.

```mermaid
flowchart TD
    Start(["●  Mulai\n(Dipicu scheduler / pg_cron)"])
    CheckSecret["Verifikasi x-queue-secret header"]
    Unauthorized{"Secret\nvalid?"}
    Return401["Return 401 Unauthorized"]
    CheckConfig{"WA_API_BASE_URL,\nUSERNAME, PASSWORD\ntersedia?"}
    Return500Config["Return 500:\n'Missing WA API configuration'"]
    DequeueRPC["RPC: dequeue_wa_notifications()\n→ Ambil hingga N baris\n(status: pending → processing)"]
    AnyRows{"Ada baris\ndi antrian?"}
    ReturnEmpty["Return 200: {processed:0, sent:0, failed:0}"]
    CheckGateway["GET /app/status\n(timeout 8 detik)"]
    LogStatus["INSERT ke wa_notification_logs\n(endpoint: /app/status, response)"]
    GatewayOk{"Gateway\nmerespons OK?"}
    RetryAll["UPDATE wa_notification_queue:\nstatus → pending (retry) atau failed\nExponential backoff (1,2,4…30 mnt)"]
    Return502["Return 502: gateway unavailable"]

    %% Per-message loop
    ForEachRow["Proses setiap baris antrian\n(loop)"]
    HasImage{"Baris memiliki\nimage_url?"}

    %% Text
    SendText["POST /send/message\n(JSON: phone, message)\ntimeout 20 detik"]
    TextSuccess{"Response\nOK?"}

    %% Image
    DownloadImage["Download gambar dari Storage URL\n(timeout 20 detik)"]
    ImageDownloaded{"Download\nberhasil?"}
    SendImage["POST /send/image\n(multipart: phone, image blob, caption)\ntimeout 20 detik"]
    ImageSuccess{"Response\nOK?"}

    LogSuccess["INSERT wa_notification_logs\n(success: true)"]
    UpdateSent["UPDATE wa_notification_queue:\nstatus → 'sent'\nprocessed_at = now()"]

    LogFail["INSERT wa_notification_logs\n(success: false, error_message)"]
    UpdateFail["UPDATE wa_notification_queue:\nstatus → pending (retry) atau 'failed'\nretry_count++, next_attempt_at + backoff"]

    MoreRows{"Lebih banyak\nbaris?"}
    ReturnSummary["Return 200:\n{processed, sent, failed}"]
    End(["◉  Selesai"])

    Start --> CheckSecret
    CheckSecret --> Unauthorized
    Unauthorized -->|Tidak| Return401 --> End
    Unauthorized -->|Ya| CheckConfig
    CheckConfig -->|Tidak| Return500Config --> End
    CheckConfig -->|Ya| DequeueRPC
    DequeueRPC --> AnyRows
    AnyRows -->|Tidak| ReturnEmpty --> End
    AnyRows -->|Ya| CheckGateway
    CheckGateway --> LogStatus
    LogStatus --> GatewayOk
    GatewayOk -->|Tidak| RetryAll --> Return502 --> End
    GatewayOk -->|Ya| ForEachRow

    ForEachRow --> HasImage
    HasImage -->|Tidak| SendText
    SendText --> TextSuccess
    TextSuccess -->|Ya| LogSuccess --> UpdateSent
    TextSuccess -->|Tidak| LogFail --> UpdateFail

    HasImage -->|Ya| DownloadImage
    DownloadImage --> ImageDownloaded
    ImageDownloaded -->|Tidak| LogFail --> UpdateFail
    ImageDownloaded -->|Ya| SendImage
    SendImage --> ImageSuccess
    ImageSuccess -->|Ya| LogSuccess --> UpdateSent
    ImageSuccess -->|Tidak| LogFail --> UpdateFail

    UpdateSent --> MoreRows
    UpdateFail --> MoreRows
    MoreRows -->|Ya| ForEachRow
    MoreRows -->|Tidak| ReturnSummary --> End
```

## Langkah-langkah

| # | Langkah | Keterangan |
|---|---|---|
| 1 | Verifikasi secret | Header `x-queue-secret` divalidasi agar tidak bisa dipanggil sembarangan |
| 2 | Cek konfigurasi | `WA_API_BASE_URL`, `WA_API_USERNAME`, `WA_API_PASSWORD` harus tersedia |
| 3 | Dequeue | RPC `dequeue_wa_notifications()` mengunci baris dan mengubah status ke `processing` |
| 4 | Health check | GET `/app/status` ke gateway (timeout 8 detik) — jika gagal, seluruh batch di-retry |
| 5 | Kirim pesan (teks) | POST `/send/message` dengan JSON `{phone, message}` |
| 6 | Kirim pesan (gambar) | Download gambar dari Storage URL, lalu POST `/send/image` multipart |
| 7 | Catat log | Setiap percobaan pengiriman dicatat di `wa_notification_logs` |
| 8 | Update status | Berhasil → `sent`; Gagal → `pending` (retry) atau `failed` (maks retry tercapai) |
| 9 | Exponential backoff | Delay retry: 1, 2, 4, 8, … maks 30 menit |

## Tabel Trigger → Penerima WA

| Tabel Sumber | Event | Penerima | Dengan Foto |
|---|---|---|---|
| `majun_transactions` | Setor majun | Penjahit | ✅ |
| `percas_stock` | Tambah stok perca | Manager | ✅ |
| `perca_transactions` | Ambil perca | Manager | ❌ |
| `expeditions` | Pengiriman | Manager | ✅ |
| `salary_withdrawals` | Penarikan upah | Penjahit | ❌ |
