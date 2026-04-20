# Manage Percas (Stok Perca) Feature

## Overview

The Manage Percas feature handles incoming perca (textile remnant fabric) stock from factories. It tracks individual perca sacks with unique sack codes, records perca-take transactions (distributing perca to tailors for majun production), and provides stock charts.

## Architecture

Following Clean Architecture principles:

```
lib/features/manage_percas/
├── data/
│   ├── models/
│   │   ├── perca_stock_model.dart             # PercasStock model (incoming stock)
│   │   └── perca_transactions_model.dart      # PercaTransaction model (distribution to tailors)
│   └── repositories/
│       ├── perca_repository.dart              # CRUD for percas_stock table
│       └── perca_transactions_repository.dart # CRUD for perca_transactions table
├── domain/
│   └── providers/
│       ├── perca_provider.dart                # Providers for perca stock
│       └── perca_transactions_provider.dart   # Providers for perca transactions
└── presentations/
    └── screens/
        ├── manage_perca_screen.dart            # Main menu screen
        ├── add_perca_screen.dart               # Form: add new perca stock from factory
        ├── add_perca_history_screen.dart       # History of incoming perca stock
        ├── add_perca_transaction_screen.dart   # Form: distribute perca to tailor
        ├── perca_transaction_history_screen.dart # History of perca distributions
        └── widgets/
            └── chart.dart                     # Monthly stock chart widget
```

## Data Models

### `PercasStock` — Incoming Stock from Factory

| Field | Type | Description |
|---|---|---|
| `idFactory` | `String` | FK → factories.id |
| `dateEntry` | `DateTime` | Date of stock entry |
| `percaType` | `String` | `'kaos'` or `'kain'` |
| `weight` | `double` | Weight in kg |
| `deliveryProof` | `String` | Storage URL of proof photo |
| `sackCode` | `String` | Auto-generated: `K-{weight}` (kaos) or `B-{weight}` (kain) |

### Sack Code Generation
```dart
static String generateSackCode(String percaType, double weight) {
  final prefix = percaType.toLowerCase() == 'kaos' ? 'K' : 'B';
  final weightStr = weight == weight.roundToDouble()
      ? weight.toInt().toString()
      : weight.toStringAsFixed(2);
  return '$prefix-$weightStr'; // e.g. K-45, B-25.50
}
```

### `PercaTransaction` — Distribution to Tailor

| Field | Type | Description |
|---|---|---|
| `id` | `String` | UUID primary key |
| `idTailor` | `String` | FK → tailors.id |
| `idPercaStock` | `String` | FK → percas_stock.id |
| `dateEntry` | `DateTime` | Date of distribution |
| `weight` | `double` | Weight distributed |
| `staffId` | `String?` | FK → profiles.id (recording staff) |

## Features

### 1. Tambah Stok Perca (Add Incoming Stock)
- Select factory supplier
- Input perca type (kaos/kain), weight, entry date
- Upload delivery proof photo
- Auto-generates sack code on save
- WA notification to factory contact triggered automatically

### 2. Riwayat Stok Masuk (Incoming Stock History)
- List all perca stock entries with factory and date filters
- Shows sack code, type, weight, status (`tersedia` / `terambil`)
- View delivery proof photos

### 3. Ambil Perca (Distribute to Tailor)
- Select available perca sacks (`tersedia` status)
- Assign to a tailor
- On save: updates perca status to `terambil`, updates tailor's `total_stock`
- WA notification queued to tailor and manager

### 4. Riwayat Distribusi (Distribution History)
- List all perca-take transactions
- Filter by tailor, factory, date
- Monthly chart showing stock in/out

## Database Schema

### `percas_stock`
```sql
CREATE TABLE percas_stock (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_factory UUID NOT NULL REFERENCES factories(id),
  date_entry TIMESTAMPTZ NOT NULL,
  perca_type TEXT NOT NULL CHECK (perca_type IN ('kaos', 'kain')),
  weight NUMERIC(10,2) NOT NULL,
  delivery_proof TEXT,
  sack_code TEXT,
  status TEXT DEFAULT 'tersedia' CHECK (status IN ('tersedia', 'terambil')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### `perca_transactions`
```sql
CREATE TABLE perca_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_tailor UUID NOT NULL REFERENCES tailors(id),
  id_perca_stock UUID NOT NULL REFERENCES percas_stock(id),
  date_entry DATE NOT NULL,
  weight NUMERIC(10,2),
  staff_id UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### DB Triggers & RPCs
- `after_perca_transaction_insert` — updates `percas_stock.status = 'terambil'`, increments `tailors.total_stock`, enqueues WA notifications
- `rpc_get_perca_transactions_with_tailors()` — RPC returning joined perca transaction data

## Providers

| Provider | Returns | Description |
|---|---|---|
| `percaStockListProvider` | `AsyncValue<List<PercasStock>>` | All perca stock entries |
| `availablePercaStockProvider` | `AsyncValue<List<PercasStock>>` | Only `tersedia` sacks |
| `percaTransactionsProvider` | `AsyncValue<List<PercaTransaction>>` | Distribution history |
| `percaMonthlyStatsProvider` | `AsyncValue<Map>` | Monthly aggregated stats for chart |

## Navigation

Access from:
- Admin Dashboard → Bottom Nav "Perca"
- Manager Dashboard → Quick Access "Perca"

## Row Level Security (RLS)

| Operation | Policy |
|---|---|
| SELECT | Authenticated users |
| INSERT | Authenticated users |
| UPDATE | Admin and Manager roles only |
| DELETE | Admin and Manager roles only |

## Future Improvements

- [ ] Barcode/QR scanning for sack codes
- [ ] Export stock report to Excel/PDF
- [ ] Low-stock alerts
- [ ] Multi-sack distribution in one transaction
