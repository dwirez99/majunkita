# Manage Factories Feature

## Overview

The Manage Factories feature handles CRUD operations for factory (pabrik) data. Factories are the supplier entities that deliver raw perca fabric to the majunkita supply chain.

## Architecture

Following Clean Architecture principles:

```
lib/features/manage_factories/
├── data/
│   ├── models/
│   │   └── factory_model.dart             # FactoryModel — factory data
│   └── repositories/
│       └── factory_repository.dart        # CRUD operations via Supabase
├── domain/
│   └── providers/
│       └── factory_provider.dart          # Riverpod providers & notifiers
└── presentations/
    └── screens/
        ├── factory_list_screen.dart        # List all factories with search
        └── factory_form_dialog.dart        # Add / Edit factory dialog
```

## Data Model

### `FactoryModel`

| Field | Type | Description |
|---|---|---|
| `id` | `String` | UUID primary key |
| `factoryName` | `String` | Factory / company name |
| `address` | `String` | Factory address |
| `noTelp` | `String` | Contact phone number (used for WA notifications) |

## Features

### 1. List Factories
- Scrollable list of all registered factories
- Search by factory name
- Pull-to-refresh

### 2. Add Factory
- Form dialog: factory name, address, phone number
- Input validation
- Success/error feedback

### 3. Edit Factory
- Pre-filled form dialog with existing data
- Same validation as add

### 4. Delete Factory
- Confirmation dialog before deletion
- Cascades: perca stock entries linked to deleted factory remain (factory FK is preserved)

## Database Schema

### `factories`
```sql
CREATE TABLE factories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  factory_name VARCHAR(255) NOT NULL,
  address TEXT,
  no_telp VARCHAR(20),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### RLS Policies

| Operation | Policy |
|---|---|
| SELECT | Authenticated users |
| INSERT | Admin and Manager roles |
| UPDATE | Admin and Manager roles |
| DELETE | Admin and Manager roles |

## Providers

| Provider | Returns | Description |
|---|---|---|
| `factoriesListProvider` | `AsyncValue<List<FactoryModel>>` | All factories |
| `filteredFactoriesProvider` | `AsyncValue<List<FactoryModel>>` | Factories filtered by search query |
| `factorySearchQueryProvider` | `String` | Current search query |
| `factoryManagementProvider` | `FactoryNotifier` | Handles create/update/delete actions |

## Navigation

Access from:
- Admin Dashboard → Management Menu → "Kelola Pabrik"
- Manage Percas → "Tambah Stok" → factory selection dropdown

## Code Examples

### Get all factories
```dart
final factoriesAsync = ref.watch(factoriesListProvider);
```

### Create factory
```dart
await ref.read(factoryManagementProvider.notifier).createFactory(
  factoryName: 'PT Tekstil Maju',
  address: 'Jl. Industri No. 10',
  noTelp: '0812345678',
);
```

### Update factory
```dart
await ref.read(factoryManagementProvider.notifier).updateFactory(
  id: 'factory-uuid',
  factoryName: 'PT Tekstil Baru',
  address: 'Jl. Industri No. 20',
  noTelp: '0812345679',
);
```

### Delete factory
```dart
await ref.read(factoryManagementProvider.notifier).deleteFactory('factory-uuid');
```

## WhatsApp Notifications

When a perca stock entry from a factory is recorded, a WA notification is automatically sent to the factory's `no_telp` number (via the WA notification queue) to confirm receipt.

## Future Improvements

- [ ] Factory contact person information
- [ ] Factory rating / performance tracking
- [ ] Multiple contact numbers per factory
- [ ] Import factory list from Excel
