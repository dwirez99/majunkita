// Model untuk User Profile (Generic)
class UserProfile {
  final String id;
  final String? username;
  final String namaLengkap;
  final String email;
  final String noTelp;
  final String role; // 'admin', 'driver', 'manager'

  UserProfile({
    required this.id,
    this.username,
    required this.namaLengkap,
    required this.email,
    required this.noTelp,
    required this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String?,
      namaLengkap: json['nama_lengkap'] as String? ?? 'Tanpa Nama',
      email: json['email'] as String? ?? '',
      noTelp: json['no_telp'] as String? ?? '-',
      role: json['role'] as String? ?? 'staff',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nama_lengkap': namaLengkap,
      'email': email,
      'no_telp': noTelp,
      'role': role,
    };
  }
}

// Model untuk Karyawan Admin
class KaryawanAdmin {
  final String id;
  final String? username;
  final String nama; // Alias untuk namaLengkap (untuk backward compatibility)
  final String namaLengkap;
  final String email;
  final String noTelp;
  final String? alamat; // Deprecated, kept for backward compatibility

  KaryawanAdmin({
    required this.id,
    this.username,
    required this.nama,
    required this.namaLengkap,
    required this.email,
    required this.noTelp,
    this.alamat,
  });

  factory KaryawanAdmin.fromJson(Map<String, dynamic> json) {
    final namaLengkap = json['nama_lengkap'] as String? ?? 'Tanpa Nama';
    return KaryawanAdmin(
      id: json['id'] as String,
      username: json['username'] as String?,
      namaLengkap: namaLengkap,
      nama: namaLengkap, // Use namaLengkap as nama
      email: json['email'] as String? ?? '',
      noTelp: json['no_telp'] as String? ?? '-',
      alamat: json['alamat'] as String?, // Deprecated field
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nama_lengkap': namaLengkap,
      'email': email,
      'no_telp': noTelp,
    };
  }
}

// Model untuk Driver
class Driver {
  final String id;
  final String? username;
  final String nama; // Alias untuk namaLengkap (untuk backward compatibility)
  final String namaLengkap;
  final String email;
  final String noTelp;
  final String? alamat; // Deprecated, kept for backward compatibility

  Driver({
    required this.id,
    this.username,
    required this.nama,
    required this.namaLengkap,
    required this.email,
    required this.noTelp,
    this.alamat,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    final namaLengkap = json['nama_lengkap'] as String? ?? 'Tanpa Nama';
    return Driver(
      id: json['id'] as String,
      username: json['username'] as String?,
      namaLengkap: namaLengkap,
      nama: namaLengkap, // Use namaLengkap as nama
      email: json['email'] as String? ?? '',
      noTelp: json['no_telp'] as String? ?? '-',
      alamat: json['alamat'] as String?, // Deprecated field
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nama_lengkap': namaLengkap,
      'email': email,
      'no_telp': noTelp,
    };
  }
}