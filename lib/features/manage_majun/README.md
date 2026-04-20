# Manage Majun Feature

## Overview

The Manage Majun feature handles the core transaction recording for majun (textile-waste cloth) and limbah (textile waste) submitted by tailors. Each submission automatically calculates the tailor's earned wage and triggers a WhatsApp notification.

## Architecture

Following Clean Architecture principles:

```
lib/features/manage_majun/
├── data/
│   ├── model/
│   │   └── majun_transactions_model.dart  # MajunTransactionsModel, LimbahTransactionsModel, SetorMajunResult
│   └── repositories/
│       └── majun_repository.dart          # Database operations via Supabase
├── domain/
│   └── providers/
│       └── majun_provider.dart            # Riverpod providers & notifiers
└── presentations/
    └── screens/
        ├── manage_majun_screen.dart        # Menu screen (Setor Majun / Setor Limbah / Riwayat)
        ├── setor_majun_screen.dart         # Form to record majun submission
        ├── setor_limbah_screen.dart        # Form to record limbah submission
        └── majun_history_screen.dart       # Transaction history with filters
```

## Data Models

### `MajunTransactionsModel`
Represents a majun submission from a tailor.

| Field | Type | Description |
|---|---|---|
| `id` | `String?` | UUID primary key |
| `idTailor` | `String` | FK → tailors.id |
| `dateEntry` | `DateTime` | Date of submission |
| `weightMajun` | `double` | Weight in kg |
| `earnedWage` | `double` | Auto-calculated wage by DB trigger |
| `staffId` | `String?` | FK → profiles.id (recording staff) |
| `deliveryProof` | `String?` | Storage URL of proof photo |
| `tailorName` | `String?` | Joined from tailors (RPC result) |

### `LimbahTransactionsModel`
Represents a limbah (waste) submission — similar to majun but without wage calculation.

| Field | Type | Description |
|---|---|---|
| `id` | `String?` | UUID primary key |
| `idTailor` | `String` | FK → tailors.id |
| `dateEntry` | `DateTime` | Date of submission |
| `weightLimbah` | `double` | Weight in kg |
| `staffId` | `String?` | FK → profiles.id |
| `deliveryProof` | `String?` | Storage URL of proof photo |
| `tailorName` | `String?` | Joined from tailors (RPC result) |

## Features

### 1. Setor Majun (Record Majun Submission)
- Select tailor from list
- Input majun weight (kg)
- Upload delivery proof photo (compressed before upload)
- On save: DB trigger auto-calculates `earned_wage` and updates `tailors.balance`
- Success dialog shows weight and earned wage
- WA notification queued automatically

### 2. Setor Limbah (Record Limbah Submission)
- Select tailor from list
- Input limbah weight (kg)
- Upload delivery proof photo
- On save: DB trigger reduces `tailors.total_stock` without adding wage

### 3. Riwayat (Transaction History)
- Filterable list of all majun and limbah transactions
- Filter by tailor, date range, type
- View delivery proof photos in full screen
- Paginated loading

## Database Schema

### `majun_transactions`
```sql
CREATE TABLE majun_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_tailor UUID NOT NULL REFERENCES tailors(id),
  date_entry DATE NOT NULL,
  weight_majun NUMERIC(10,2) NOT NULL,
  earned_wage NUMERIC(12,2) DEFAULT 0,
  staff_id UUID REFERENCES profiles(id),
  delivery_proof TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### `limbah_transactions`
```sql
CREATE TABLE limbah_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_tailor UUID NOT NULL REFERENCES tailors(id),
  date_entry DATE NOT NULL,
  weight_limbah NUMERIC(10,2) NOT NULL,
  staff_id UUID REFERENCES profiles(id),
  delivery_proof TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### DB Triggers
- `after_majun_insert` — calculates `earned_wage` from the tailor's wage rate, updates `tailors.balance` and `tailors.total_stock`, enqueues WA notification
- `after_limbah_insert` — deducts `tailors.total_stock` without wage adjustment

## Providers

| Provider | Returns | Description |
|---|---|---|
| `majunHistoryProvider` | `AsyncValue<List<MajunTransactionsModel>>` | Paginated majun history |
| `limbahHistoryProvider` | `AsyncValue<List<LimbahTransactionsModel>>` | Paginated limbah history |
| `majunNotifierProvider` | `MajunNotifier` | Handles setor majun/limbah actions |

## Activity Flow — Setor Majun

```
1. User opens Manage Majun → Setor Majun
2. Selects tailor, enters weight, uploads photo
3. App calls majun_repository.setorMajun()
4. Supabase inserts into majun_transactions
5. DB trigger fires:
   a. Calculates earned_wage (weight × tailor's wage_rate)
   b. Updates tailors.balance += earned_wage
   c. Inserts row into wa_notification_queue
6. App reads returned earned_wage and shows success dialog
7. Edge function processes WA queue → sends WhatsApp to tailor & manager
```

## WhatsApp Notification

After a successful setor majun, a WA message is automatically queued containing:
- Tailor name
- Submission date
- Majun weight
- Earned wage

## Navigation

Access from:
- Admin Dashboard → Bottom Nav "Majun"
- Manager Dashboard → Quick Access "Setor Majun"

## Future Improvements

- [ ] Bulk majun entry for multiple tailors
- [ ] PDF/Excel export of transaction history
- [ ] Offline draft support
