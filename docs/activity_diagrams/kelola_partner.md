# Activity Diagram — Kelola Partner (Manajemen Pengguna)

**Aktor:** Admin (kelola Driver & Penjahit Sistem) / Manager (kelola Admin, Driver & Penjahit Sistem)  
**Deskripsi:** Admin dan Manager dapat menambah, mengubah, dan menghapus akun pengguna sistem (Admin, Driver). Pembuatan dan penghapusan akun dilakukan melalui Supabase Edge Functions karena memerlukan akses service role.

```mermaid
flowchart TD
    Start(["●  Mulai"])
    OpenPartnerScreen["Buka halaman Kelola Partner"]
    SelectCategory{"Kategori\nyang dikelola?"}

    LoadAdmins["Muat daftar Admin\n(profiles WHERE role='admin')"]
    LoadDrivers["Muat daftar Driver\n(profiles WHERE role='driver')"]

    ChooseActionAdmin{"Aksi Admin?"}
    ChooseActionDriver{"Aksi Driver?"}

    %% Add
    OpenAddForm["Buka form Tambah Pengguna"]
    FillAddForm["Isi:\n- Nama lengkap\n- Email\n- Username (auto dari email)\n- No. Telp\n- Password\n- Alamat (opsional)"]
    ValidateAdd{"Form valid?\n(email unik, password ≥ 6 char)"}
    ShowAddError["Tampilkan pesan\nvalidasi / error server"]
    InvokeCreateUser["Edge Function: create-user\n(email, password, name, role, no_telp, username, address)"]
    CreateAuth["Supabase Auth: createUser()"]
    CreateProfile["INSERT ke tabel profiles\n(via DB trigger setelah auth.users)"]
    ShowAddSuccess["Tampilkan pesan berhasil\nRefresh daftar"]

    %% Edit
    SelectUser["Pilih Pengguna"]
    OpenEditForm["Buka form Edit Pengguna\n(pre-fill data saat ini)"]
    FillEditForm["Ubah:\nnama / email / no. telp /\npassword (opsional) / alamat"]
    ValidateEdit{"Form valid?"}
    ShowEditError["Tampilkan pesan error"]
    InvokeUpdateUser["Edge Function: update-user\n(user_id, name, email, no_telp,\npassword?, role?, address?)"]
    UpdateAuth["Supabase Auth: updateUser()"]
    UpdateProfile["UPDATE tabel profiles"]
    ShowEditSuccess["Tampilkan pesan berhasil\nRefresh daftar"]

    %% Delete
    ConfirmDelete{"Konfirmasi\nhapus?"}
    InvokeDeleteUser["Edge Function: delete-user\n(user_id)"]
    DeleteAuth["Supabase Auth: deleteUser()\n→ Cascade: profiles terhapus"]
    ShowDeleteSuccess["Tampilkan pesan berhasil\nRefresh daftar"]

    End(["◉  Selesai"])

    Start --> OpenPartnerScreen
    OpenPartnerScreen --> SelectCategory

    SelectCategory -->|"Admin (hanya Manager)"| LoadAdmins --> ChooseActionAdmin
    SelectCategory -->|"Driver"| LoadDrivers --> ChooseActionDriver

    ChooseActionAdmin -->|"Tambah"| OpenAddForm
    ChooseActionDriver -->|"Tambah"| OpenAddForm
    OpenAddForm --> FillAddForm --> ValidateAdd
    ValidateAdd -->|Tidak| ShowAddError --> FillAddForm
    ValidateAdd -->|Ya| InvokeCreateUser
    InvokeCreateUser --> CreateAuth --> CreateProfile --> ShowAddSuccess --> LoadAdmins

    ChooseActionAdmin -->|"Edit"| SelectUser
    ChooseActionDriver -->|"Edit"| SelectUser
    SelectUser --> OpenEditForm --> FillEditForm --> ValidateEdit
    ValidateEdit -->|Tidak| ShowEditError --> FillEditForm
    ValidateEdit -->|Ya| InvokeUpdateUser
    InvokeUpdateUser --> UpdateAuth --> UpdateProfile --> ShowEditSuccess --> LoadAdmins

    ChooseActionAdmin -->|"Hapus"| SelectUser
    ChooseActionDriver -->|"Hapus"| SelectUser
    SelectUser --> ConfirmDelete
    ConfirmDelete -->|Tidak| LoadAdmins
    ConfirmDelete -->|Ya| InvokeDeleteUser --> DeleteAuth --> ShowDeleteSuccess --> LoadAdmins

    LoadAdmins --> End
    LoadDrivers --> End
```

## Langkah-langkah

| # | Aksi | Keterangan |
|---|---|---|
| 1 | Pilih kategori | Admin: hanya Driver; Manager: Admin & Driver |
| 2 | **Tambah** | Form isi data → validasi → Edge Function `create-user` → Supabase Auth + profiles |
| 3 | **Edit** | Pre-fill form → validasi → Edge Function `update-user` → update Auth + profiles |
| 4 | **Hapus** | Konfirmasi → Edge Function `delete-user` → hapus dari `auth.users` (cascade ke `profiles`) |

> **Catatan:**  
> - Semua operasi CRUD pada akun pengguna melewati **Supabase Edge Functions** karena memerlukan `service_role` key.  
> - Admin **tidak dapat** mengelola sesama Admin; hanya Manager yang dapat mengelola akun Admin.  
> - Username di-generate otomatis dari bagian sebelum `@` pada email.
