class profiles {
  final String id;
  final String namaLengkap;
  final String? username;
  final String email;
  final String role;
  final String noTelp;

  profiles({
    required this.id,
    required this.namaLengkap,
    this.username,
    required this.email,
    required this.role,
    required this.noTelp,
  });

  factory profiles.fromMap(Map<String, dynamic> map) {
    return profiles(
      id: map['id'],
      namaLengkap: map['nama_lengkap'],
      username: map['username'],
      email: map['email'],
      role: map['role'],
      noTelp: map['no_telp'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_lengkap': namaLengkap,
      'username': username,
      'email': email,
      'role': role,
      'no_telp': noTelp,
    };
  }
}