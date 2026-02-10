class Profiles {
  final String id;
  final String name;
  final String? username;
  final String email;
  final String role;
  final String noTelp;

  Profiles({
    required this.id,
    required this.name,
    this.username,
    required this.email,
    required this.role,
    required this.noTelp,
  });

  factory Profiles.fromMap(Map<String, dynamic> map) {
    return Profiles(
      id: map['id'],
      name: map['name'],
      username: map['username'],
      email: map['email'],
      role: map['role'],
      noTelp: map['no_telp'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'role': role,
      'no_telp': noTelp,
    };
  }
}