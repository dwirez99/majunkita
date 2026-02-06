# Authentication Setup Guide

## Overview
This application uses Supabase Authentication with role-based access control. Users are authenticated via email/password and routed to different dashboards based on their assigned role.

## Authentication Flow

### 1. App Initialization (`main.dart`)
```
App Start → Initialize Supabase → Load AuthWrapper
```

### 2. AuthWrapper (Authentication Gate)
The `AuthWrapper` widget is the entry point that determines what screen to show:

- **If Loading**: Shows loading indicator
- **If Not Authenticated**: Shows Login Screen
- **If Authenticated**: Routes to appropriate dashboard based on user role

### 3. Login Process
1. User enters email and password in `LoginScreen`
2. Credentials are validated through `AuthRepository`
3. User profile is fetched from `profiles` table
4. User is routed based on their role:
   - `admin` → MainScreen (with admin privileges)
   - `manager` → MainScreen (with manager privileges)
   - `driver` → Driver Dashboard (coming soon)
   - `partner_pabrik` → Partner Dashboard (coming soon)

### 4. Session Management
- Authentication state is monitored via `onAuthStateChange` listener
- When user logs out, they are automatically redirected to Login Screen
- Session persists across app restarts (handled by Supabase)

## File Structure

```
lib/
├── main.dart                          # App entry point & AuthWrapper
├── core/
│   └── api/
│       └── supabase_client_api.dart  # Supabase client instance
└── features/
    └── auth/
        ├── data/
        │   └── repositories/
        │       └── auth_repository.dart  # Auth business logic
        └── presentations/
            └── screens/
                └── login_screen.dart     # Login UI
```

## Key Components

### AuthWrapper
**Location**: `lib/main.dart`

**Responsibilities**:
- Check current authentication state on app start
- Listen for authentication state changes
- Route users to appropriate screens based on login status and role

**Key Methods**:
- `_checkAuthState()`: Checks if user is logged in and fetches their role
- `_setupAuthListener()`: Monitors sign-in/sign-out events
- `_getScreenForRole()`: Returns appropriate screen based on user role

### LoginScreen
**Location**: `lib/features/auth/presentations/screens/login_screen.dart`

**Features**:
- Email/password validation
- Loading state during login
- Error handling with user-friendly messages
- Role-based navigation after successful login

### AuthRepository
**Location**: `lib/features/auth/data/repositories/auth_repository.dart`

**Methods**:
- `signIn()`: Authenticate user with email/password
- `signOut()`: Log out current user
- `getCurrentUserProfile()`: Fetch user profile including role
- `createUserByAdmin()`: Create new users via `create-user` Edge Function (admin only)

## User Roles

| Role | Access Level | Dashboard |
|------|--------------|-----------|
| `admin` | Full access | MainScreen (with all nav items) |
| `manager` | Manager access | MainScreen (with limited nav items) |
| `driver` | Driver access | Driver Dashboard (coming soon) |
| `partner_pabrik` | Partner access | Partner Dashboard (coming soon) |

## Edge Functions (Server-Side Operations)

### create-user Function
**Purpose**: Creates new users with admin privileges
**Location**: `supabase/functions/create-user/index.ts`
**Triggered By**: `ManagePartnerRepository.createAdmin()` and `createDriver()`

**Features**:
- Validates requesting user is admin/manager
- Creates user in `auth.users` table
- Auto-populates `profiles` table via trigger
- Returns user ID and confirmation

### update-user Function
**Purpose**: Updates user information (profile data, password, email)
**Location**: `supabase/functions/update-user/index.ts`
**Triggered By**: `ManagePartnerRepository.updateUser()`

**Features**:
- Validates requesting user is admin/manager
- Updates auth credentials (email, password)
- Updates user profile data
- Supports optional password reset

### delete-user Function
**Purpose**: Deletes users from the system
**Location**: `supabase/functions/delete-user/index.ts`
**Triggered By**: `ManagePartnerRepository.deleteUser()`

**Features**:
- Validates requesting user is admin/manager
- Prevents self-deletion
- Cascades delete to `profiles` table
- Returns confirmation

## Database Schema

### profiles Table
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE,
  nama_lengkap TEXT NOT NULL,
  email TEXT,
  role TEXT NOT NULL CHECK (role IN ('admin', 'manager', 'driver', 'karyawan_admin', 'partner_pabrik', 'penjahit')),
  no_telp TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Auto-Trigger
**Function**: `handle_new_user()`
**Trigger**: `on_auth_user_created`
**Purpose**: Automatically creates profile when user is created in `auth.users`

**Trigger**: `on_profiles_updated`
**Function**: `handle_updated_at()`
**Purpose**: Auto-updates `updated_at` timestamp

## User Management (Manage Partner Module)

### Create User
**UI**: Manage Admin/Driver Screen → "Tambah [Role] Baru"
**Repository Method**: `ManagePartnerRepository.createAdmin()` or `createDriver()`
**Flow**:
1. Form dialog collects: nama, username, email, no_telp, password
2. Calls `create-user` Edge Function
3. Function creates user in auth.users
4. Trigger auto-creates profile
5. List refreshes with new user

### Update User
**UI**: Manage Admin/Driver Screen → Edit button on user card
**Repository Method**: `ManagePartnerRepository.updateUser()`
**Flow**:
1. Form dialog pre-fills existing data
2. User modifies: nama, username, no_telp, password (optional)
3. Calls `update-user` Edge Function
4. Function updates auth and profile data
5. List refreshes with updated data

### Delete User
**UI**: Manage Admin/Driver Screen → Delete button on user card
**Repository Method**: `ManagePartnerRepository.deleteUser()`
**Flow**:
1. Confirmation dialog asks for confirmation
2. User confirms deletion
3. Calls `delete-user` Edge Function
4. Function deletes from auth.users (cascade deletes profile)
5. List refreshes, user removed

### Search Users
**UI**: Manage Admin/Driver Screen → Search field
**Repository Method**: `ManagePartnerRepository.searchAdmins()` or `searchDrivers()`
**Flow**:
1. User enters search query
2. Filters list by `nama_lengkap` (ILIKE)
3. Results update in real-time

## How to Test Authentication

### 1. Test Login
1. Run the app: `flutter run`
2. You should see the Login Screen
3. Enter valid credentials
4. You should be routed to the appropriate dashboard

### 2. Test Logout
1. From any dashboard, tap the logout icon in the AppBar
2. Confirm logout in the dialog
3. You should be redirected to the Login Screen

### 3. Test Session Persistence
1. Log in to the app
2. Close the app completely
3. Reopen the app
4. You should still be logged in (no need to login again)

### 4. Test Role-Based Routing
1. Log in with different user roles
2. Verify you're routed to the correct dashboard
3. Check navigation items match the role privileges

### 5. Test User Management (Admin/Manager only)
1. Log in as admin/manager user
2. Navigate to "Kelola Partner Admin" or "Kelola Partner Driver"
3. Test Create: Click "Tambah [Role] Baru", fill form, submit
4. Test Update: Click edit button, modify data, save
5. Test Delete: Click delete button, confirm deletion
6. Test Search: Enter search query, verify filtering

## Adding Logout to Other Screens

To add logout functionality to any screen:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

// In your widget:
IconButton(
  icon: const Icon(Icons.logout),
  onPressed: () async {
    await Supabase.instance.client.auth.signOut();
    // AuthWrapper listener will handle navigation automatically
  },
)
```

## Protecting Routes

The current implementation protects routes automatically:
- Unauthenticated users can only see the Login Screen
- Authenticated users are routed based on their role
- Invalid roles trigger an error screen with logout option

## Environment Variables

Required in `.env` file:
```
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

**Note**: The app has fallback values in `main.dart` if `.env` fails to load.

## Edge Function Deployment

All Edge Functions are deployed in Supabase Dashboard:

### Required Functions:
- ✅ `create-user` - Creates new users
- ✅ `update-user` - Updates user information  
- ✅ `delete-user` - Deletes users

### Deployment Steps:
1. Go to Supabase Dashboard → Edge Functions
2. Click "Deploy new function"
3. Name it exactly as shown above
4. Copy code from `supabase/functions/{name}/index.ts`
5. Click Deploy

### To View Function Logs:
1. Supabase Dashboard → Edge Functions
2. Click the function name
3. View execution logs for debugging

## Security Best Practices

1. ✅ Passwords are never stored in plain text (handled by Supabase)
2. ✅ Email validation on login form
3. ✅ Role verification from database (not from client)
4. ✅ Session tokens managed by Supabase SDK
5. ✅ Automatic redirect on unauthorized access
6. ✅ Edge Functions validate admin/manager permissions server-side
7. ✅ Prevent self-deletion in delete function
8. ✅ CORS headers configured on all Edge Functions

## Troubleshooting

### "Function not found" error (404)
- Verify the Edge Function is deployed in Supabase Dashboard
- Check function name matches exactly (case-sensitive)
- Try refreshing the page and redeploying

### "Profile not found" error
- Ensure the user exists in the `profiles` table
- Check if the database trigger is working correctly

### App stays on loading screen
- Check Supabase connection
- Verify `.env` file contains correct credentials
- Check console for error messages

### Login successful but shows wrong dashboard
- Verify user's role in the `profiles` table
- Check role string matches exactly (case-insensitive)

### User logged out unexpectedly
- Check Supabase session timeout settings
- Verify network connection
- Check for auth errors in console

### Can't create/update/delete users
- Verify you're logged in as admin or manager
- Check the user's role in `profiles` table has admin/manager
- Review Edge Function logs in Supabase Dashboard
- Ensure database trigger `on_auth_user_created` exists

## Future Improvements

- [ ] Add "Remember Me" option
- [ ] Implement password reset flow
- [ ] Add biometric authentication
- [ ] Implement refresh token handling
- [ ] Add offline mode support
- [ ] Create Driver Dashboard
- [ ] Create Partner Dashboard