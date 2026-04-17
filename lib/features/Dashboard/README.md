# Dashboard Feature

## Overview

The Dashboard feature provides role-specific home screens for each user type in the MajunKita application. Each role sees a tailored view with quick-access menus, summary cards, and navigation relevant to their responsibilities.

## Supported Roles & Screens

| Role | Screen | Description |
|---|---|---|
| `admin` | `DashboarAdminScreen` | Full access — perca, majun, ekspedisi, notifications |
| `manager` | `DashboardManagerScreen` | Manage partners, view reports, perca & majun |
| `driver` | `DashboardDriverScreen` | Record outbound expeditions |

## Architecture

```
lib/features/Dashboard/
├── data/
│   ├── models/
│   │   ├── admin_dashboard_models.dart    # Summary data models for Admin
│   │   └── manager_dashboard_model.dart   # Summary data models for Manager
│   └── repositories/
│       └── dashboard_repository.dart      # Fetches aggregated stats from Supabase RPCs
├── domain/
│   └── providers/
│       └── dashboard_providers.dart       # Riverpod providers for dashboard data
└── presentations/
    ├── screens/
    │   ├── dashboard_admin_screen.dart    # Admin home screen
    │   ├── dashboard_manager_screen.dart  # Manager home screen
    │   └── dashboard_driver_screen.dart   # Driver home screen
    └── widgets/
        ├── dashboard_appbar.dart          # Shared AppBar with logout
        ├── dashboard_bottom_bar.dart      # Bottom navigation bar
        ├── management_menu.dart           # Grid menu for management actions
        ├── quick_acces_menu.dart          # Quick-access shortcut buttons
        ├── summary_card.dart              # Stat summary card widget
        └── user_profile_card.dart         # Logged-in user profile display
```

## Navigation

The dashboard is reached after a successful login via `AuthWrapper` in `main.dart`. Role-based routing:

```
Login → AuthWrapper
          ├── admin   → DashboarAdminScreen
          ├── manager → DashboardManagerScreen
          └── driver  → DashboardDriverScreen
```

## Admin Dashboard Features

- **Summary Cards**: Total penjahit, stok perca, ekspedisi bulan ini
- **Quick Access**: Shortcut to Setor Majun, Tambah Perca, Tambah Ekspedisi
- **Bottom Navigation**: Home | Perca | Majun | Ekspedisi
- **WA Notification badge**: Unread/failed notification count

## Manager Dashboard Features

- **Summary Cards**: Overview of operations under management
- **Management Menu**: Navigate to Kelola Partner (admin/driver accounts)
- **Quick Access**: Common actions

## Driver Dashboard Features

- **Add Expedition**: Record outbound shipments with proof photos
- **Expedition History**: View past shipments

## Providers

| Provider | Returns | Description |
|---|---|---|
| `adminDashboardSummaryProvider` | `AsyncValue<AdminDashboardSummary>` | Aggregated stats for admin view |
| `managerDashboardSummaryProvider` | `AsyncValue<ManagerDashboardSummary>` | Aggregated stats for manager view |
| `userProfileProvider` | `AsyncValue<Map?>` | Current logged-in user profile |
| `unreadWaNotificationsCountProvider` | `AsyncValue<int>` | Count of pending/failed WA notifications |

## Database / RPC

The dashboard data is fetched via Supabase RPCs that aggregate data server-side to minimise client-side computation:

- `get_admin_dashboard_summary()` — total tailors, stock, expeditions, balances
- `get_manager_dashboard_summary()` — similar subset for manager role

## Future Improvements

- [ ] Real-time dashboard updates via Supabase Realtime
- [ ] Charts and trend graphs
- [ ] Partner (pabrik) dashboard
