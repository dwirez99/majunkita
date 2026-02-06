# Tailor Data Management Feature

## Overview
This feature implements a complete CRUD (Create, Read, Update, Delete) system for managing tailor (penjahit) data in the MajunKita textile waste management application.

## Architecture
Following Clean Architecture principles with separation of concerns:

```
lib/features/manage_tailors/
├── data/
│   ├── models/
│   │   └── tailor_model.dart          # Data model with JSON serialization
│   └── repositories/
│       └── tailor_repository.dart      # Database operations layer
├── domain/
│   └── providers/
│       └── tailor_provider.dart        # State management (Riverpod)
└── presentations/
    ├── screens/
    │   ├── tailors_list_screen.dart    # List view with search
    │   └── tailor_form_screen.dart     # Add/Edit form
    └── widgets/
        └── (to be added if needed)
```

## Database Schema

### Table: `tailors`

```sql
CREATE TABLE public.tailors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nama_lengkap VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    no_telp VARCHAR(20) NOT NULL,
    alamat TEXT,
    spesialisasi VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Row Level Security (RLS) Policies

1. **Read (SELECT)**: Public access allowed (anyone can view tailors)
2. **Insert**: Authenticated users only
3. **Update**: Authenticated users only
4. **Delete**: Admin and Manager roles only

## Features

### 1. List Tailors
- Display all tailors in a scrollable list
- Search functionality by name
- Real-time search with debouncing
- Pull-to-refresh capability
- Empty state handling

### 2. Add Tailor
- Form validation for all required fields
- Email format validation
- User-friendly error messages
- Success feedback

### 3. Edit Tailor
- Pre-filled form with existing data
- Same validation as add
- Update confirmation

### 4. Delete Tailor
- Confirmation dialog before deletion
- User feedback on success/failure
- Restricted to admin/manager roles (enforced by RLS)

## Usage

### Navigation
Access from Admin Dashboard → "Kelola Penjahit" menu

### Code Examples

#### Get all tailors
```dart
final tailorsAsync = ref.watch(tailorsListProvider);
```

#### Search tailors
```dart
ref.read(tailorSearchQueryProvider.notifier).setQuery("search term");
```

#### Create tailor
```dart
await ref.read(tailorManagementProvider.notifier).createTailor(
  namaLengkap: 'John Doe',
  email: 'john@example.com',
  noTelp: '081234567890',
  alamat: 'Jl. Test No. 1',
  spesialisasi: 'Jahit Baju',
);
```

#### Update tailor
```dart
await ref.read(tailorManagementProvider.notifier).updateTailor(
  id: 'tailor-id',
  namaLengkap: 'Jane Doe',
  email: 'jane@example.com',
  noTelp: '081234567890',
);
```

#### Delete tailor
```dart
await ref.read(tailorManagementProvider.notifier).deleteTailor('tailor-id');
```

## Error Handling

The repository layer provides user-friendly error messages:

- **Duplicate email**: "Email sudah terdaftar. Gunakan email lain."
- **Network errors**: "Koneksi internet bermasalah. Periksa koneksi Anda."
- **Timeout**: "Permintaan timeout. Coba lagi."
- **Generic errors**: Displays technical details for debugging

## Logging

All operations are logged with timestamps for debugging:

```
[2024-01-01 12:00:00] [INFO] TAILOR_REPOSITORY: Fetching tailors (page: 1, limit: 20)...
[2024-01-01 12:00:01] [INFO] TAILOR_REPOSITORY: Successfully fetched 5 tailors
```

## Performance Optimizations

1. **Specific Column Selection**: Uses `.select('id, nama_lengkap, ...')` instead of `.select(*)`
2. **Pagination**: Supports pagination with configurable page size (default: 20)
3. **Auto-dispose**: List providers auto-dispose when not in use
4. **Optimistic Updates**: UI updates immediately, syncs with backend asynchronously

## Testing

Unit tests are provided for the TailorModel class in:
```
test/features/manage_tailors/tailor_model_test.dart
```

Tests cover:
- JSON serialization/deserialization
- Null value handling
- copyWith functionality
- Equality comparison

## Migration

Run the migration file to create the database table:
```
supabase/migrations/20240102000000_create_tailors_table.sql
```

## Dependencies

- `flutter_riverpod`: State management
- `supabase_flutter`: Backend integration
- Standard Flutter widgets for UI

## Future Enhancements

- [ ] Add profile pictures for tailors
- [ ] Track work history and performance metrics
- [ ] Integration with order management
- [ ] Export/import tailor data
- [ ] Advanced filtering options
