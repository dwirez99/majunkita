# Manage Partner Feature

Feature ini mengelola data Partner Admin dan Driver dalam aplikasi MajuKita.

## 📁 Struktur Folder

```
manage_partner/
├── data/
│   ├── models/
│   │   └── manage_partner_models.dart    # Model data untuk Admin & Driver
│   └── repositories/
│       └── manage_partner_repository.dart # Repository untuk CRUD operations
├── domain/
│   └── providers/
│       └── manage_partner_providers.dart  # Riverpod providers
└── presentations/
    ├── screens/
    │   ├── manage_partner_screen.dart     # Main screen (pilih Admin/Driver)
    │   ├── manage_admin_screen.dart       # List & CRUD Admin
    │   └── manage_driver_screen.dart      # List & CRUD Driver
    └── widgets/
        └── staff_form_dialog.dart         # Unified form dialog untuk Admin & Driver
```

## 🎯 Fitur Utama

### 1. **Manajemen Partner Admin**
- ✅ Tambah Partner Admin baru
- ✅ Edit data Partner Admin (nama, no telp, alamat)
- ✅ Hapus Partner Admin
- ✅ Cari Partner Admin berdasarkan nama
- ✅ Tampilan list dengan card hijau

### 2. **Manajemen Driver**
- ✅ Tambah Driver baru
- ✅ Edit data Driver (nama, no telp, alamat)
- ✅ Hapus Driver
- ✅ Cari Driver berdasarkan nama
- ✅ Tampilan list dengan card hijau

## 🚀 Cara Penggunaan

### Navigasi ke Manage Partner

Dari Dashboard Manager:
```dart
import 'package:majunkita/features/manage_partner/presentations/screens/manage_partner_screen.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ManagePartnerScreen(),
  ),
);
```

## 📊 Data Models

### KaryawanAdmin
```dart
class KaryawanAdmin {
  final String id;
  final String nama;
  final String email;
  final String noTelp;
  final String alamat;
}
```

### Driver
```dart
class Driver {
  final String id;
  final String nama;
  final String email;
  final String noTelp;
  final String alamat;
}
```

## 🔌 Providers (Riverpod 3.x)

### Admin Providers
- `adminsListProvider` - Mendapatkan semua admin
- `filteredAdminsProvider` - Admin yang terfilter berdasarkan search
- `adminSearchQueryProvider` - State untuk search query
- `selectedAdminProvider` - Admin yang dipilih untuk edit
- `adminNotifierProvider` - Notifier untuk CRUD operations

### Driver Providers
- `driversListProvider` - Mendapatkan semua driver
- `filteredDriversProvider` - Driver yang terfilter berdasarkan search
- `driverSearchQueryProvider` - State untuk search query
- `selectedDriverProvider` - Driver yang dipilih untuk edit
- `driverNotifierProvider` - Notifier untuk CRUD operations

## 💾 Database

Data disimpan di tabel `profiles` di Supabase dengan struktur:

| Column    | Type   | Description                          |
|-----------|--------|--------------------------------------|
| id        | uuid   | Primary key (dari auth.users)        |
| nama      | text   | Nama lengkap                         |
| email     | text   | Email (dari auth.users)              |
| role      | text   | 'karyawan_admin' atau 'driver'       |
| no_telp   | text   | Nomor telepon                        |
| alamat    | text   | Alamat lengkap                       |

## 🎨 Desain UI

### Warna
- **Card hijau**: `Colors.green[400]` (sesuai design mockup)
- **Background form**: `Colors.grey[300]` dan `Colors.grey[400]`
- **Button**: `Colors.grey[600]` untuk aksi utama

### Komponen
- **Avatar**: CircleAvatar hitam dengan icon putih
- **Search bar**: TextField dengan icon search
- **Form dialog**: Modal dialog dengan field lengkap
- **Action buttons**: Edit (icon) dan Delete (icon)

## 📝 Catatan Penting

1. **Email tidak bisa diedit** setelah user dibuat (disabled saat mode edit)
2. **Password** hanya diminta saat create user baru (minimal 6 karakter)
3. **Delete operation** akan menghapus user dari auth dan profiles table
4. **Search** menggunakan ILIKE untuk case-insensitive search
5. **Create user** menggunakan Supabase Edge Function `create-user`

## 🔐 Autentikasi & Otorisasi

Feature ini **hanya bisa diakses oleh Manager**. Pastikan:
- User sudah login sebagai Manager
- Dashboard Manager sudah memiliki navigasi ke ManagePartnerScreen

## 🐛 Troubleshooting

### Error: "Gagal membuat admin/driver"
- Pastikan Supabase Edge Function `create-user` sudah di-deploy
- Cek koneksi internet dan Supabase credentials

### Data tidak muncul
- Refresh provider dengan menekan tombol "Terbaru"
- Cek apakah role di database sudah benar ('karyawan_admin' atau 'driver')

### Search tidak berfungsi
- Pastikan field 'nama' di database terisi
- Provider search akan otomatis refresh saat query berubah

## 🔄 Update Future

Fitur yang bisa ditambahkan:
- [ ] Filter berdasarkan status (aktif/nonaktif)
- [ ] Export data ke Excel/PDF
- [ ] Detail view untuk melihat riwayat aktivitas
- [ ] Bulk upload dari CSV
- [ ] Reset password untuk admin/driver

## 📞 Support

Untuk pertanyaan atau issue terkait feature ini, silakan hubungi tim development.