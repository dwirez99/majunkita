# Manage Expeditions Feature

## Overview

The Manage Expeditions feature tracks all outbound shipments of majun goods delivered to customers via expedition partners. It records driver, destination, sack count, total weight, and proof of delivery photos.

## Architecture

Following Clean Architecture principles:

```
lib/features/manage_expeditions/
├── data/
│   ├── models/
│   │   ├── expedition_model.dart          # ExpeditionModel — shipment record
│   │   └── expedition_partner_model.dart  # ExpeditionPartnerModel — logistics company
│   └── repositories/
│       ├── expedition_repository.dart         # CRUD for expeditions table
│       └── expedition_partner_repository.dart # CRUD for expedition_partners table
├── domain/
│   └── expedition_provider.dart          # Riverpod providers & notifiers
└── presentations/
    └── screens/
        ├── manage_expeditions_screen.dart          # Main menu screen
        ├── add_expedition_screen.dart              # Form: record new shipment
        ├── expedition_history_screen.dart          # Expedition history list
        └── manage_expedition_partners_screen.dart  # Manage logistics partner data
```

## Data Models

### `ExpeditionModel` — Shipment Record

| Field | Type | Description |
|---|---|---|
| `id` | `String` | UUID primary key |
| `idPartner` | `String` | FK → profiles.id (driver) |
| `expeditionDate` | `DateTime` | Date of shipment |
| `destination` | `String` | Delivery destination |
| `sackNumber` | `int` | Number of sacks shipped |
| `totalWeight` | `int` | Total weight in kg |
| `proofOfDelivery` | `String` | Storage URL of proof photo |
| `idExpeditionPartner` | `String?` | FK → expedition_partners.id |
| `partnerName` | `String?` | Joined driver name from profiles |
| `expeditionPartnerName` | `String?` | Joined logistics company name |

### `ExpeditionPartnerModel` — Logistics Company

| Field | Type | Description |
|---|---|---|
| `id` | `String` | UUID primary key |
| `name` | `String` | Company name |
| `contactNumber` | `String?` | Phone number |
| `address` | `String?` | Company address |

## Features

### 1. Tambah Ekspedisi (Record Shipment)
- Select driver (from profiles with role `driver`)
- Select expedition partner (logistics company)
- Input destination, number of sacks, total weight, expedition date
- Upload proof of delivery photo
- On save: stock balance updated, WA notification queued

### 2. Riwayat Ekspedisi (Expedition History)
- Chronological list of all shipments
- Filter by driver, date range, destination
- View proof of delivery photos
- Shows sack count, weight, driver, and logistics partner

### 3. Kelola Mitra Ekspedisi (Manage Expedition Partners)
- Add, edit, delete logistics company data
- Used as reference when recording new shipments

## Database Schema

### `expeditions`
```sql
CREATE TABLE expeditions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_partner UUID NOT NULL REFERENCES profiles(id),   -- driver
  expedition_date DATE NOT NULL,
  destination TEXT NOT NULL,
  sack_number INTEGER NOT NULL,
  total_weight INTEGER NOT NULL,
  proof_of_delivery TEXT,
  id_expedition_partner UUID REFERENCES expedition_partners(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### `expedition_partners`
```sql
CREATE TABLE expedition_partners (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  contact_number TEXT,
  address TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### RLS Policies

| Operation | Policy |
|---|---|
| SELECT | Authenticated users |
| INSERT | Driver, Admin, Manager roles |
| UPDATE | Admin and Manager roles only |
| DELETE | Admin and Manager roles only |

## Providers

| Provider | Returns | Description |
|---|---|---|
| `expeditionsProvider` | `AsyncValue<List<ExpeditionModel>>` | All expeditions |
| `expeditionPartnersProvider` | `AsyncValue<List<ExpeditionPartnerModel>>` | All expedition partners |
| `expeditionNotifierProvider` | `ExpeditionNotifier` | Handles add/update/delete |

## Navigation

Access from:
- Admin Dashboard → Bottom Nav "Ekspedisi"
- Driver Dashboard → "Tambah Ekspedisi" / "Riwayat Ekspedisi"

## Activity Flow — Tambah Ekspedisi

```
1. Driver opens Driver Dashboard → Tambah Ekspedisi
2. Fills form: destination, sacks, weight, date, selects logistics partner
3. Uploads proof of delivery photo
4. App calls expedition_repository.addExpedition()
5. Supabase inserts into expeditions table
6. WA notification queued for manager
7. Success message shown
```

## Future Improvements

- [ ] GPS tracking integration
- [ ] QR code scanning for sack verification
- [ ] Customer signature capture
- [ ] Real-time shipment status updates
