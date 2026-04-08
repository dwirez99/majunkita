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
12. [Appendix — Self-Hosting on Raspberry Pi / Android Box with Cloudflare Tunnel](#appendix--self-hosting-on-raspberry-pi--android-box-with-cloudflare-tunnel)

---

## Prerequisites

- [Supabase CLI](https://supabase.com/docs/guides/cli) installed and logged in
- A running Supabase project
- A host for the WA gateway — this can be a VPS/cloud VM **or** a local device such as a Raspberry Pi or Android Box (see the [Appendix](#appendix--self-hosting-on-raspberry-pi--android-box-with-cloudflare-tunnel) for the local-device + Cloudflare Tunnel setup)
- Docker or a Go 1.21+ environment on that host
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
    │  HTTPS (via Cloudflare Tunnel  ─────────────────────────────┐
    │         OR direct VPS URL)                                  │
    ▼                                                             │
go-whatsapp-web-multidevice ← local device (RPi / Android Box)   │
  or VPS                            │                            │
                               cloudflared ──► Cloudflare Edge ──┘
    │
    ├─► GET  /app/status          (health check)
    ├─► POST /send/message        (text-only notification)
    └─► POST /send/image          (notification with proof photo)
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

---

## Appendix — Self-Hosting on Raspberry Pi / Android Box with Cloudflare Tunnel

If you don't want to rent a cloud VPS, you can run the WA gateway on a Raspberry Pi (3B+, 4, or 5) or an Android Box such as the **HG680-P**, then expose it to the internet for free using a **Cloudflare Zero Trust Tunnel**. This gives you a stable public HTTPS URL without opening firewall ports or having a static IP.

### Hardware Notes

| Device | Architecture | Recommended OS |
|---|---|---|
| Raspberry Pi 3B+ | ARMv7 (32-bit) | Raspberry Pi OS Lite (32-bit) |
| Raspberry Pi 4 / 5 | ARM64 | Raspberry Pi OS Lite (64-bit) or Ubuntu 22.04 |
| HG680-P | ARM64 (Cortex-A53) | [Armbian for HG680-P](https://armbian.com) (Debian/Ubuntu base) |

> The HG680-P does not have an official Armbian build in the main repo; community builds exist on the Armbian forum. Make sure you have a working Armbian (or CoreELEC/EmuELEC) installation with SSH access before continuing.

---

### A. Install Docker on the Device

#### Raspberry Pi (Raspberry Pi OS / Ubuntu)

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker using the official convenience script
curl -fsSL https://get.docker.com | sudo sh

# Add your user to the docker group (avoid needing sudo every time)
sudo usermod -aG docker $USER
newgrp docker

# Verify
docker --version
```

#### HG680-P (Armbian — Debian/Ubuntu base)

The same script works on Armbian:

```bash
sudo apt update && sudo apt upgrade -y
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
newgrp docker
docker --version
```

> If Docker's ARM64 image for `go-whatsapp-web-multidevice` is not available, build from source (see [Option B in Step 1](#option-b--build-from-source)).

---

### B. Run the WA Gateway

```bash
# Create a persistent data directory
mkdir -p ~/wa-data

# Pull and run the container
docker run -d \
  --name wa-gateway \
  --restart unless-stopped \
  -p 127.0.0.1:3000:3000 \
  -v ~/wa-data:/app/storages \
  aldinokemal2104/go-whatsapp-web-multidevice:latest \
  --port 3000 \
  --basic-auth-username admin \
  --basic-auth-password your_strong_password
```

> Binding to `127.0.0.1:3000` (loopback only) is intentional — the Cloudflare Tunnel will be the **only** public entry point, so you never expose the port to the local network directly.

Check it is running:

```bash
docker ps
docker logs wa-gateway
```

---

### C. Set Up Cloudflare Zero Trust Tunnel

#### Prerequisites

- A free [Cloudflare account](https://dash.cloudflare.com/sign-up)
- A domain added to Cloudflare (can be a free `*.workers.dev` subdomain won't work here; you need a real domain managed by Cloudflare, or use a `trycloudflare.com` temporary tunnel for testing — see note at the end of this section)

#### 1. Install `cloudflared` on the device

```bash
# Download the latest release for ARM64
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64 \
  -o /usr/local/bin/cloudflared
chmod +x /usr/local/bin/cloudflared

# For ARMv7 (32-bit Raspberry Pi OS):
# curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm \
#   -o /usr/local/bin/cloudflared

cloudflared --version
```

#### 2. Log in to Cloudflare

```bash
cloudflared tunnel login
```

A browser URL will be printed. Open it on any machine, select your domain, and authorize. A certificate file will be saved at `~/.cloudflared/cert.pem`.

#### 3. Create a named tunnel

```bash
cloudflared tunnel create wa-gateway
```

This outputs a **Tunnel ID** (UUID). Note it down — you will need it in the next step.

#### 4. Create the tunnel config file

Create `~/.cloudflared/config.yml`:

```yaml
tunnel: <your-tunnel-id>
credentials-file: /home/<your-user>/.cloudflared/<your-tunnel-id>.json

ingress:
  - hostname: wa.yourdomain.com
    service: http://localhost:3000
  - service: http_status:404
```

Replace:
- `<your-tunnel-id>` with the UUID from the previous step
- `<your-user>` with your Linux username (e.g. `pi` or `root`)
- `wa.yourdomain.com` with the subdomain you want to use (e.g. `wa.majunkita.com`)

#### 5. Add the DNS record

```bash
cloudflared tunnel route dns wa-gateway wa.yourdomain.com
```

This automatically creates a `CNAME` record in Cloudflare DNS pointing `wa.yourdomain.com` → the tunnel.

#### 6. Run the tunnel

```bash
cloudflared tunnel run wa-gateway
```

Test connectivity from another machine:

```bash
curl https://wa.yourdomain.com/app/status \
  -u admin:your_strong_password
```

#### 7. Run the tunnel as a system service (auto-start on boot)

```bash
sudo cloudflared service install
sudo systemctl enable cloudflared
sudo systemctl start cloudflared
```

Verify:

```bash
sudo systemctl status cloudflared
```

---

### D. Use the Tunnel URL in Supabase Secrets

Now that the gateway is publicly reachable at `https://wa.yourdomain.com`, set it as `WA_API_BASE_URL`:

```bash
supabase secrets set \
  WA_API_BASE_URL="https://wa.yourdomain.com" \
  WA_API_USERNAME="admin" \
  WA_API_PASSWORD="your_strong_password" \
  WA_API_DEVICE_ID="<device-id>" \
  WA_QUEUE_SECRET="<random-secret-string>" \
  --project-ref <your-project-ref>
```

The Supabase Edge Function will now call the WA gateway through the Cloudflare Tunnel over HTTPS.

---

### E. Quick Test with a Temporary Tunnel (no domain required)

If you just want to test without a domain, use Cloudflare's free temporary URL:

```bash
cloudflared tunnel --url http://localhost:3000
```

It will print a URL like `https://random-name.trycloudflare.com`. Use that as `WA_API_BASE_URL` temporarily. This URL changes every time you restart `cloudflared`, so it is **not suitable for production**.

---

### Troubleshooting (local device + tunnel)

| Symptom | Likely cause | Fix |
|---|---|---|
| `docker: image not found` | No ARM64 Docker image published | Build from source (see [Step 1 Option B](#option-b--build-from-source)) |
| `cloudflared: connection refused` | WA gateway not running | `docker ps` — restart if stopped |
| Tunnel connects but returns 502 | Gateway bound to wrong address | Ensure gateway listens on `0.0.0.0:3000` or `127.0.0.1:3000` matching the config |
| Session lost after device reboot | Docker container stopped | `--restart unless-stopped` flag ensures auto-restart; verify with `docker ps` |
| Cloudflare tunnel not starting | Service not installed | Run `sudo cloudflared service install` again |
