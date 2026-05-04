# Activity Diagram — Login

**Aktor:** Admin / Driver / Manager  
**Deskripsi:** Pengguna masuk ke sistem menggunakan email/username dan password. Sistem memetakan username ke email via RPC sebelum memanggil Supabase Auth, lalu mengarahkan ke dashboard sesuai peran.

```mermaid
flowchart TD
    Start(["●  Mulai"])
    InputCredentials["Masukkan\nUsername/Email & Password"]
    IsEmail{"Mengandung\n'@'?"}
    UseEmailDirect["Gunakan sebagai Email langsung"]
    RPCLookup["RPC: get_email_by_username()\n→ Cari email berdasarkan username"]
    UsernameFound{"Email\nditemukan?"}
    ShowErrorUsername["Tampilkan pesan:\n'Username tidak ditemukan'"]
    SupabaseAuth["Supabase Auth:\nsignInWithPassword(email, password)"]
    AuthSuccess{"Login\nberhasil?"}
    FetchProfile["Ambil profil dari tabel 'profiles'\n(role, nama, no_telp)"]
    ProfileFound{"Profil\nada?"}
    ShowErrorAuth["Tampilkan pesan error\n(salah password / email belum konfirmasi)"]
    DetermineRole{"role == ?"}
    DashboardAdmin["Redirect ke\nDashboard Admin"]
    DashboardDriver["Redirect ke\nDashboard Driver"]
    DashboardManager["Redirect ke\nDashboard Manager"]
    End(["◉  Selesai"])

    Start --> InputCredentials
    InputCredentials --> IsEmail
    IsEmail -->|Ya| UseEmailDirect
    IsEmail -->|Tidak| RPCLookup
    RPCLookup --> UsernameFound
    UsernameFound -->|Tidak| ShowErrorUsername
    ShowErrorUsername --> InputCredentials
    UsernameFound -->|Ya| SupabaseAuth
    UseEmailDirect --> SupabaseAuth
    SupabaseAuth --> AuthSuccess
    AuthSuccess -->|Tidak| ShowErrorAuth
    ShowErrorAuth --> InputCredentials
    AuthSuccess -->|Ya| FetchProfile
    FetchProfile --> ProfileFound
    ProfileFound -->|Tidak| ShowErrorAuth
    ProfileFound -->|Ya| DetermineRole
    DetermineRole -->|admin| DashboardAdmin
    DetermineRole -->|driver| DashboardDriver
    DetermineRole -->|manager| DashboardManager
    DashboardAdmin --> End
    DashboardDriver --> End
    DashboardManager --> End
```

## Langkah-langkah

| # | Langkah | Keterangan |
|---|---|---|
| 1 | Input identifier & password | Identifier bisa berupa email (mengandung `@`) atau username |
| 2 | Resolusi username → email | Jika bukan email, RPC `get_email_by_username()` dijalankan |
| 3 | Autentikasi Supabase | `signInWithPassword(email, password)` |
| 4 | Ambil profil | Query `profiles` untuk mendapatkan `role` |
| 5 | Redirect by role | Admin → Dashboard Admin, Driver → Dashboard Driver, Manager → Dashboard Manager |
