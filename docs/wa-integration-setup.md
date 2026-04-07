# WhatsApp API Integration — Setup Guide

This guide covers everything needed to get the WhatsApp notification integration up and running for the **majunkita** project. The integration uses [go-whatsapp-web-multidevice](https://github.com/aldinokemal/go-whatsapp-web-multidevice) as the WA gateway and Supabase Edge Functions as the queue worker.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [Step 1 — Run the WA Gateway Server](#step-1--run-the-wa-gateway-server)
4. [Step 2 — Scan QR Code to Link WA Account](#step-2--scan-qr-code-to-link-wa-account)
5. [Step 3 — Apply the Database Migration](#step-3--apply-the-database-migration)
6. [Step 4 — Deploy the Edge Function](#step-4--deploy-the-edge-function)
7. [Step 5 — Set Edge Function Secrets](#step-5--set-edge-function-secrets)
8. [Step 6 — Schedule the Queue Worker](#step-6--schedule-the-queue-worker)
9. [Environment Variables Reference](#environment-variables-reference)
10. [Testing the Integration](#testing-the-integration)
11. [Monitoring & Troubleshooting](#monitoring--troubleshooting)

---

## Prerequisites

- [Supabase CLI](https://supabase.com/docs/guides/cli) installed and logged in
- A running Supabase project
- A server (VPS/cloud VM) reachable from Supabase Edge Functions to host the WA gateway
- Docker or a Go 1.21+ environment on that server
- A WhatsApp account (dedicated phone number recommended)

---

## Architecture Overview

```
Flutter App
    │ INSERT
    ▼
[majun_transactions / percas_stock / expeditions]
    │ AFTER INSERT trigger
    ▼
[wa_notification_queue]  ← status: pending
    │ periodic HTTP call
    ▼
[process-wa-notification-queue]  ← Supabase Edge Function
    │
    ├─► GET  /app/status          (health check)
    ├─► POST /send/message        (text-only notification)
    └─► POST /send/image          (notification with proof photo)
         │
         ▼
   go-whatsapp-web-multidevice
         │
         ▼
   WhatsApp recipient
    │ result recorded
    ▼
[wa_notification_logs]
```

---

## Step 1 — Run the WA Gateway Server

### Option A — Docker (recommended)

```bash
docker run -d \
  --name wa-gateway \
  --restart unless-stopped \
  -p 3000:3000 \
  -v $(pwd)/wa-data:/app/storages \
  -e APP_BASIC_AUTH_USERNAME=admin \
  -e APP_BASIC_AUTH_PASSWORD=your_strong_password \
  aldinokemal2104/go-whatsapp-web-multidevice:latest \
  --port 3000 \
  --basic-auth-username admin \
  --basic-auth-password your_strong_password
```

> **Tip:** Replace `admin` and `your_strong_password` with real credentials. These values will be used as `WA_API_USERNAME` and `WA_API_PASSWORD` in the Edge Function secrets.

### Option B — Build from source

```bash
git clone https://github.com/aldinokemal/go-whatsapp-web-multidevice.git
cd go-whatsapp-web-multidevice
go build -o wa-gateway ./cmd/main.go
./wa-gateway --port 3000 \
  --basic-auth-username admin \
  --basic-auth-password your_strong_password
```

---

## Step 2 — Scan QR Code to Link WA Account

1. Open the gateway web UI at `http://<your-server>:3000` in a browser.
2. Click **"Login"** or navigate to `GET /app/login`.
3. Scan the displayed QR code with the WhatsApp app on the dedicated phone.
4. After scanning, the session is saved in the `storages/` directory (persisted across restarts via the Docker volume).
5. Verify the session is active:

```bash
curl -u admin:your_strong_password http://<your-server>:3000/app/status
```

Expected response:

```json
{"code": 200, "message": "Success", "results": {"device": "...", "is_login": true}}
```

### Retrieve the Device ID

```bash
curl -u admin:your_strong_password http://<your-server>:3000/app/devices
```

Copy the `device` value from the response — this is your `WA_API_DEVICE_ID`.

---

## Step 3 — Apply the Database Migration

The migration file is located at:

```
supabase/migrations/20260407164000_add_whatsapp_notification_queue.sql
```

It creates:

| Object | Purpose |
|---|---|
| `wa_notification_queue` | Async delivery queue |
| `wa_notification_logs` | Per-attempt delivery log |
| `normalize_wa_jid()` | Normalizes phone → `628xxx@s.whatsapp.net` |
| `enqueue_wa_notification()` | Inserts a row into the queue |
| `dequeue_wa_notifications()` | Atomically dequeues a batch for processing |
| Triggers on 3 source tables | Automatically enqueue on each INSERT |

### Apply via Supabase CLI

```bash
supabase db push
```

Or apply manually against the remote database:

```bash
supabase db reset --db-url "postgresql://postgres:<password>@db.<project-ref>.supabase.co:5432/postgres"
```

---

## Step 4 — Deploy the Edge Function

```bash
supabase functions deploy process-wa-notification-queue \
  --project-ref <your-project-ref>
```

The function source is at:

```
supabase/functions/process-wa-notification-queue/index.ts
```

---

## Step 5 — Set Edge Function Secrets

All secrets are injected as environment variables into the Edge Function. Run the following commands (replace placeholders with real values):

```bash
supabase secrets set \
  WA_API_BASE_URL="http://<your-server>:3000" \
  WA_API_USERNAME="admin" \
  WA_API_PASSWORD="your_strong_password" \
  WA_API_DEVICE_ID="<device-id-from-step-2>" \
  WA_QUEUE_SECRET="<random-secret-string>" \
  --project-ref <your-project-ref>
```

To verify the secrets were set:

```bash
supabase secrets list --project-ref <your-project-ref>
```

---

## Step 6 — Schedule the Queue Worker

The Edge Function must be called periodically to drain the queue. Choose one of the following approaches:

### Option A — Supabase pg_cron (recommended)

Enable `pg_cron` in your Supabase project (Dashboard → Database → Extensions), then run:

```sql
SELECT cron.schedule(
  'process-wa-queue',
  '* * * * *',   -- every 1 minute
  $$
    SELECT net.http_post(
      url    := 'https://<project-ref>.supabase.co/functions/v1/process-wa-notification-queue',
      headers := '{"Content-Type": "application/json", "x-queue-secret": "<WA_QUEUE_SECRET>"}'::jsonb,
      body   := '{}'::jsonb
    );
  $$
);
```

Requires the `pg_net` extension as well (enable it in Extensions).

### Option B — External cron (crontab / GitHub Actions / etc.)

```bash
# Example crontab entry (runs every minute)
* * * * * curl -s -X POST \
  -H "x-queue-secret: <WA_QUEUE_SECRET>" \
  -H "Content-Type: application/json" \
  https://<project-ref>.supabase.co/functions/v1/process-wa-notification-queue
```

---

## Environment Variables Reference

| Variable | Required | Description |
|---|---|---|
| `WA_API_BASE_URL` | ✅ | Base URL of the go-whatsapp-web-multidevice server, e.g. `http://your-server:3000` |
| `WA_API_USERNAME` | ✅ | HTTP Basic Auth username configured on the WA gateway |
| `WA_API_PASSWORD` | ✅ | HTTP Basic Auth password configured on the WA gateway |
| `WA_API_DEVICE_ID` | Optional | Device ID / session name. Required if the gateway hosts multiple sessions |
| `WA_QUEUE_SECRET` | Optional | Shared secret sent as `x-queue-secret` header to protect the endpoint |

> `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are injected automatically by the Supabase runtime.

---

## Testing the Integration

### 1. Manual queue trigger

Call the Edge Function directly:

```bash
curl -X POST \
  -H "x-queue-secret: <WA_QUEUE_SECRET>" \
  -H "Content-Type: application/json" \
  https://<project-ref>.supabase.co/functions/v1/process-wa-notification-queue
```

Expected successful response:

```json
{"success": true, "processed": 5, "sent": 5, "failed": 0}
```

### 2. Insert a test notification directly into the queue

```sql
INSERT INTO public.wa_notification_queue (
  event_type, source_table, source_id,
  recipient_role, recipient_phone, message
) VALUES (
  'test', 'manual', gen_random_uuid(),
  'driver', '628123456789@s.whatsapp.net',
  'Test pesan dari majunkita 🎉'
);
```

Then trigger the worker manually (see above) and check `wa_notification_logs` for the result.

### 3. Check delivery logs

```sql
SELECT
  q.event_type,
  q.recipient_phone,
  q.status,
  q.retry_count,
  l.response_status,
  l.success,
  l.error_message,
  l.created_at
FROM public.wa_notification_queue q
LEFT JOIN public.wa_notification_logs l ON l.queue_id = q.id
ORDER BY l.created_at DESC
LIMIT 20;
```

---

## Monitoring & Troubleshooting

### Queue is not draining

- Confirm the pg_cron or external cron schedule is active.
- Confirm `WA_API_BASE_URL`, `WA_API_USERNAME`, `WA_API_PASSWORD` are set correctly.
- Check Edge Function logs: Dashboard → Edge Functions → `process-wa-notification-queue` → Logs.

### All items stuck in `processing` status

This can happen if the Edge Function crashed mid-run. Reset them manually:

```sql
UPDATE public.wa_notification_queue
SET status = 'pending', next_attempt_at = now()
WHERE status = 'processing';
```

### WA gateway returns 401

- Verify the Basic Auth credentials match between the gateway startup flags and the Edge Function secrets.

### WA gateway returns `is_login: false`

- The WA session has expired. Go to `http://<your-server>:3000` and scan the QR code again.
- Consider using a dedicated WhatsApp number to avoid session conflicts.

### Phone number format issues

Phone numbers are automatically normalized to JID format (`628xxx@s.whatsapp.net`) by the `normalize_wa_jid()` database function. Acceptable input formats:

| Input | Normalized |
|---|---|
| `08123456789` | `08123456789@s.whatsapp.net` |
| `+6281234567` | `6281234567@s.whatsapp.net` |
| `628123456789` | `628123456789@s.whatsapp.net` |
| `628123456789@s.whatsapp.net` | `628123456789@s.whatsapp.net` (no-op) |

> **Note:** The normalization strips non-numeric characters but does **not** auto-prepend the country code. Ensure phone numbers stored in `tailors.no_telp` and `profiles.no_telp` include the full country code (e.g. `628...`).
