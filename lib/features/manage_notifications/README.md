# Manage Notifications (WhatsApp Notifications) Feature

## Overview

The Manage Notifications feature provides admin visibility into the WhatsApp notification queue. It shows the status of each queued notification (pending, processing, sent, failed), allows admins to retry failed messages, and displays delivery logs.

## Architecture

```
lib/features/manage_notifications/
├── data/
│   ├── models/
│   │   └── wa_notification_item_model.dart  # WaNotificationItemModel
│   └── repositories/
│       └── wa_notifications_repository.dart # Fetch queue & trigger retries
├── domain/
│   └── providers/
│       └── wa_notifications_provider.dart   # Riverpod providers
└── presentations/
    └── screens/
        └── admin_notifications_screen.dart  # Admin notification dashboard
```

## Data Model

### `WaNotificationItemModel`

| Field | Type | Description |
|---|---|---|
| `id` | `int` | Primary key |
| `eventType` | `String` | Type of event (e.g. `majun_transaction`, `perca_take`) |
| `sourceTable` | `String` | Originating DB table |
| `sourceId` | `String` | UUID of the source record |
| `recipientRole` | `String` | Target role (e.g. `penjahit`, `manager`) |
| `recipientPhone` | `String` | Recipient phone number |
| `message` | `String` | WA message body |
| `imageUrl` | `String?` | Optional image URL (proof photo) |
| `status` | `String` | `pending` / `processing` / `sent` / `failed` |
| `retryCount` | `int` | Number of retries so far |
| `maxRetries` | `int` | Maximum retry attempts (default: 5) |
| `nextAttemptAt` | `DateTime?` | Scheduled time for next retry |
| `lastError` | `String?` | Last error message |
| `createdAt` | `DateTime` | When the notification was queued |
| `processedAt` | `DateTime?` | When the notification was processed |
| `latestResponseStatus` | `int?` | HTTP response code from WA gateway |
| `latestResponseBody` | `String?` | Response body from WA gateway |
| `latestSuccess` | `bool?` | Whether the latest attempt succeeded |

## Notification Statuses

| Status | Meaning |
|---|---|
| `pending` | Queued, waiting to be processed |
| `processing` | Currently being sent by Edge Function |
| `sent` | Successfully delivered to WA gateway |
| `failed` | All retries exhausted |

## Event Types

| Event | Triggered By |
|---|---|
| `majun_transaction` | New majun submission (setor majun) |
| `limbah_transaction` | New limbah submission |
| `perca_take` | Perca distributed to tailor |
| `expedition_created` | New expedition recorded |
| `salary_withdrawal` | Tailor salary withdrawal processed |

## Features

### 1. Notification List
- Displays all WA notifications with status badges
- Filter by status: All / Pending / Sent / Failed
- Shows recipient, message, event type, timestamp

### 2. Notification Detail
- Full message body
- WA gateway HTTP response status and body
- Retry count and next retry time

### 3. Retry Failed Notifications
- Manual retry button for failed notifications
- Resets status to `pending` for re-processing by Edge Function

### 4. Badge Count on Dashboard
- Admin Dashboard shows count of `pending` + `failed` notifications as a badge indicator

## Database Schema

### `wa_notification_queue`
```sql
CREATE TABLE wa_notification_queue (
  id BIGSERIAL PRIMARY KEY,
  event_type TEXT NOT NULL,
  source_table TEXT,
  source_id TEXT,
  recipient_role TEXT,
  recipient_phone TEXT NOT NULL,
  message TEXT NOT NULL,
  image_url TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending','processing','sent','failed')),
  retry_count INTEGER DEFAULT 0,
  max_retries INTEGER DEFAULT 5,
  next_attempt_at TIMESTAMPTZ DEFAULT NOW(),
  last_error TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  processed_at TIMESTAMPTZ
);
```

### `wa_notification_logs`
```sql
CREATE TABLE wa_notification_logs (
  id BIGSERIAL PRIMARY KEY,
  notification_id BIGINT REFERENCES wa_notification_queue(id),
  response_status INTEGER,
  response_body TEXT,
  success BOOLEAN,
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

## Edge Function: `process-wa-notification-queue`

The Supabase Edge Function `process-wa-notification-queue` runs on a schedule (every minute via `pg_cron`) to:

1. Fetch all `pending` notifications where `next_attempt_at <= NOW()`
2. Mark them as `processing`
3. Send each message via the WA Gateway API
4. On success → set status `sent`, record log
5. On failure → increment `retry_count`, set exponential `next_attempt_at`, or mark `failed` if max retries reached

## Providers

| Provider | Returns | Description |
|---|---|---|
| `waNotificationsProvider` | `AsyncValue<List<WaNotificationItemModel>>` | All notifications |
| `filteredWaNotificationsProvider` | `AsyncValue<List<WaNotificationItemModel>>` | Filtered by status |
| `waNotificationStatusFilterProvider` | `String` | Current status filter |
| `unreadWaNotificationsCountProvider` | `AsyncValue<int>` | Count of pending + failed |

## Navigation

Access from:
- Admin Dashboard → AppBar notification icon (with badge count)

## Integration with WhatsApp Gateway

See full WA gateway setup guide:
```
docs/wa-integration-setup.md
```

## Future Improvements

- [ ] Real-time notification status updates via Supabase Realtime
- [ ] Bulk retry all failed notifications
- [ ] Notification templates editor
- [ ] Per-recipient notification preferences
