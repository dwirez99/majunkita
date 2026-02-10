// Model untuk User Profile (Generic)
class UserProfile {
  final String id;
  final String? username;
  final String name;
  final String email;
  final String noTelp;
  final String role; // 'admin', 'driver', 'manager'

  UserProfile({
    required this.id,
    this.username,
    required this.name,
    required this.email,
    required this.noTelp,
    required this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String?,
      name: json['name'] as String? ?? 'Tanpa Nama',
      email: json['email'] as String? ?? '',
      noTelp: json['no_telp'] as String? ?? '-',
      role: json['role'] as String? ?? 'staff',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'email': email,
      'no_telp': noTelp,
      'role': role,
    };
  }
}

// Model untuk Karyawan Admin
class Admin {
  final String id;
  final String? username;
  final String name;
  final String email;
  final String noTelp;
  final String? address;
  
  Admin({
    required this.id,
    this.username,
    required this.name,
    required this.email,
    required this.noTelp,
    this.address,
  });

  factory Admin.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? 'Tanpa Nama';
    return Admin(
      id: json['id'] as String,
      username: json['username'] as String?,
      name: name, // Use name as nama
      email: json['email'] as String? ?? '',
      noTelp: json['no_telp'] as String? ?? '-',
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'email': email,
      'no_telp': noTelp,
      'address': address, 
    };
  }
}

// Model untuk Driver
class Driver {
  final String id;
  final String? username;
  final String name;
  final String email;
  final String noTelp;
  final String? address;

  Driver({
    required this.id,
    this.username,
    required this.name,
    required this.email,
    required this.noTelp,
    this.address,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? 'Tanpa Nama';
    return Driver(
      id: json['id'] as String,
      username: json['username'] as String?,
      name: name, // Use name as nama
      email: json['email'] as String? ?? '',
      noTelp: json['no_telp'] as String? ?? '-',
      address: json['address'] as String?, 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'email': email,
      'no_telp': noTelp,
      'address': address,
    };
  }
}