# Activity Diagram — Logout

**Aktor:** Admin / Driver / Manager  
**Deskripsi:** Pengguna keluar dari sesi aktif. Supabase menghapus token sesi, dan aplikasi mengarahkan kembali ke halaman Login.

```mermaid
flowchart TD
    Start(["●  Mulai"])
    ClickLogout["Klik tombol Logout"]
    Confirm{"Konfirmasi\nLogout?"}
    Cancel["Batal — tetap di halaman saat ini"]
    SupabaseSignOut["Supabase Auth:\nsignOut()"]
    ClearLocalState["Bersihkan state lokal\n(session, cache profil)"]
    RedirectLogin["Redirect ke\nHalaman Login"]
    End(["◉  Selesai"])

    Start --> ClickLogout
    ClickLogout --> Confirm
    Confirm -->|Tidak| Cancel
    Cancel --> End
    Confirm -->|Ya| SupabaseSignOut
    SupabaseSignOut --> ClearLocalState
    ClearLocalState --> RedirectLogin
    RedirectLogin --> End
```

## Langkah-langkah

| # | Langkah | Keterangan |
|---|---|---|
| 1 | Klik Logout | Pengguna menekan tombol Logout di dashboard |
| 2 | Konfirmasi | Dialog konfirmasi ditampilkan |
| 3 | `signOut()` | Supabase menginvalidasi token sesi di server |
| 4 | Clear state | State lokal (profil, data di-cache) dibersihkan |
| 5 | Redirect Login | Pengguna kembali ke halaman Login |
