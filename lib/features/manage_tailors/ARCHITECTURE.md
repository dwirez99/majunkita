# Tailor Management Feature - Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER (UI)                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────────────────────────┐  ┌──────────────────────────────┐   │
│  │  TailorsListScreen           │  │  TailorFormScreen            │   │
│  ├──────────────────────────────┤  ├──────────────────────────────┤   │
│  │ - Search bar                 │  │ - Input fields               │   │
│  │ - List of tailors            │  │ - Validation                 │   │
│  │ - Edit/Delete buttons        │  │ - Submit button              │   │
│  │ - Empty/Error states         │  │ - Loading state              │   │
│  └──────────┬───────────────────┘  └──────────┬───────────────────┘   │
│             │                                   │                       │
│             │ ref.watch()                       │ ref.read()            │
│             ▼                                   ▼                       │
└─────────────────────────────────────────────────────────────────────────┘
              │                                   │
              │                                   │
┌─────────────────────────────────────────────────────────────────────────┐
│                         DOMAIN LAYER (Providers)                        │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  tailorsListProvider (FutureProvider)                            │  │
│  │  - Auto-updates when search query changes                        │  │
│  │  - Returns List<TailorModel>                                     │  │
│  └────────────────────────┬─────────────────────────────────────────┘  │
│                           │                                             │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  tailorSearchQueryProvider (NotifierProvider)                    │  │
│  │  - Manages search query state                                    │  │
│  │  - Triggers list refresh                                         │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  tailorManagementProvider (AsyncNotifierProvider)                │  │
│  │  - createTailor()                                                │  │
│  │  - updateTailor()                                                │  │
│  │  - deleteTailor()                                                │  │
│  │  - Invalidates list after mutations                             │  │
│  └────────────────────────┬─────────────────────────────────────────┘  │
│                           │                                             │
│                           │ uses                                        │
│                           ▼                                             │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  tailorRepositoryProvider (Provider)                             │  │
│  │  - Provides TailorRepository instance                            │  │
│  └────────────────────────┬─────────────────────────────────────────┘  │
│                           │                                             │
└───────────────────────────┼─────────────────────────────────────────────┘
                            │
                            │
┌───────────────────────────┼─────────────────────────────────────────────┐
│                         DATA LAYER                                      │
├───────────────────────────┼─────────────────────────────────────────────┤
│                           ▼                                             │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  TailorRepository                                                │  │
│  ├──────────────────────────────────────────────────────────────────┤  │
│  │ Methods:                                                         │  │
│  │  - getAllTailors(page, limit)                                    │  │
│  │  - searchTailors(query)                                          │  │
│  │  - getTailorById(id)                                             │  │
│  │  - createTailor(...)                                             │  │
│  │  - updateTailor(...)                                             │  │
│  │  - deleteTailor(id)                                              │  │
│  │  - getTailorCount()                                              │  │
│  │                                                                  │  │
│  │ Features:                                                        │  │
│  │  - Error handling with try-catch                                │  │
│  │  - User-friendly error messages                                 │  │
│  │  - Detailed logging                                             │  │
│  │  - Specific column selection                                    │  │
│  └────────────────────────┬─────────────────────────────────────────┘  │
│                           │                                             │
│                           │ uses                                        │
│                           ▼                                             │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  TailorModel                                                     │  │
│  ├──────────────────────────────────────────────────────────────────┤  │
│  │ Fields:                                                          │  │
│  │  - id: String                                                    │  │
│  │  - namaLengkap: String                                           │  │
│  │  - email: String                                                 │  │
│  │  - noTelp: String                                                │  │
│  │  - alamat: String?                                               │  │
│  │  - spesialisasi: String?                                         │  │
│  │  - createdAt: DateTime?                                          │  │
│  │  - updatedAt: DateTime?                                          │  │
│  │                                                                  │  │
│  │ Methods:                                                         │  │
│  │  - fromJson(Map)                                                 │  │
│  │  - toJson() -> Map                                               │  │
│  │  - copyWith(...)                                                 │  │
│  └────────────────────────┬─────────────────────────────────────────┘  │
│                           │                                             │
└───────────────────────────┼─────────────────────────────────────────────┘
                            │
                            │ Supabase Client
                            ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      BACKEND (Supabase/PostgreSQL)                      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  Table: tailors                                                  │  │
│  ├──────────────────────────────────────────────────────────────────┤  │
│  │  Columns:                                                        │  │
│  │   - id (UUID, PK)                                                │  │
│  │   - nama_lengkap (VARCHAR)                                       │  │
│  │   - email (VARCHAR, UNIQUE)                                      │  │
│  │   - no_telp (VARCHAR)                                            │  │
│  │   - alamat (TEXT)                                                │  │
│  │   - spesialisasi (VARCHAR)                                       │  │
│  │   - created_at (TIMESTAMP)                                       │  │
│  │   - updated_at (TIMESTAMP)                                       │  │
│  │                                                                  │  │
│  │  Indexes:                                                        │  │
│  │   - idx_tailors_email                                            │  │
│  │   - idx_tailors_nama_lengkap                                     │  │
│  │                                                                  │  │
│  │  Triggers:                                                       │  │
│  │   - on_tailors_updated (auto-update updated_at)                 │  │
│  │                                                                  │  │
│  │  RLS Policies:                                                   │  │
│  │   - SELECT: Public (anyone can read)                             │  │
│  │   - INSERT: Authenticated users                                  │  │
│  │   - UPDATE: Authenticated users                                  │  │
│  │   - DELETE: Admin & Manager only                                 │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘


DATA FLOW:

1. USER READS DATA:
   User opens TailorsListScreen
   → Screen watches tailorsListProvider
   → Provider calls TailorRepository.getAllTailors()
   → Repository queries Supabase 'tailors' table
   → Returns List<TailorModel>
   → UI displays list

2. USER SEARCHES:
   User types in search box
   → Updates tailorSearchQueryProvider
   → tailorsListProvider auto-refreshes
   → Calls TailorRepository.searchTailors(query)
   → Repository queries with .ilike() filter
   → Returns filtered List<TailorModel>
   → UI updates automatically

3. USER CREATES TAILOR:
   User fills form and submits
   → Calls tailorManagementProvider.createTailor()
   → Calls TailorRepository.createTailor()
   → Repository inserts to Supabase
   → On success: invalidates tailorsListProvider
   → List auto-refreshes
   → UI shows success message

4. USER UPDATES TAILOR:
   User edits form and submits
   → Calls tailorManagementProvider.updateTailor()
   → Calls TailorRepository.updateTailor()
   → Repository updates in Supabase
   → On success: invalidates tailorsListProvider
   → List auto-refreshes
   → UI shows success message

5. USER DELETES TAILOR:
   User confirms delete
   → Calls tailorManagementProvider.deleteTailor()
   → Calls TailorRepository.deleteTailor()
   → Repository deletes from Supabase (RLS enforced)
   → On success: invalidates tailorsListProvider
   → List auto-refreshes
   → UI shows success message


STATE MANAGEMENT (Riverpod):

- FutureProvider: For async data fetching (lists, counts)
- NotifierProvider: For simple state management (search query)
- AsyncNotifierProvider: For CRUD operations with loading states
- Provider: For dependency injection (repository)

Auto-invalidation ensures UI always shows latest data after mutations.
```
