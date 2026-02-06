/// Model untuk Tailor (Penjahit)
/// Menyimpan informasi tentang penjahit yang mengolah limbah tekstil
class TailorModel {
  final String id;
  final String namaLengkap;
  final String email;
  final String noTelp;
  final String? alamat;
  final String? spesialisasi;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TailorModel({
    required this.id,
    required this.namaLengkap,
    required this.email,
    required this.noTelp,
    this.alamat,
    this.spesialisasi,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory method untuk membuat TailorModel dari JSON (Supabase response)
  /// Menggunakan safe null handling untuk menghindari runtime error
  factory TailorModel.fromJson(Map<String, dynamic> json) {
    return TailorModel(
      id: json['id'] as String? ?? '',
      namaLengkap: json['nama_lengkap'] as String? ?? '',
      email: json['email'] as String? ?? '',
      noTelp: json['no_telp'] as String? ?? '',
      alamat: json['alamat'] as String?,
      spesialisasi: json['spesialisasi'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Method untuk mengkonversi TailorModel ke JSON (untuk insert/update)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_lengkap': namaLengkap,
      'email': email,
      'no_telp': noTelp,
      'alamat': alamat,
      'spesialisasi': spesialisasi,
      // created_at dan updated_at dihandle oleh database
    };
  }

  /// Method untuk membuat copy dengan perubahan tertentu (immutable pattern)
  TailorModel copyWith({
    String? id,
    String? namaLengkap,
    String? email,
    String? noTelp,
    String? alamat,
    String? spesialisasi,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TailorModel(
      id: id ?? this.id,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      email: email ?? this.email,
      noTelp: noTelp ?? this.noTelp,
      alamat: alamat ?? this.alamat,
      spesialisasi: spesialisasi ?? this.spesialisasi,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'TailorModel(id: $id, namaLengkap: $namaLengkap, email: $email, noTelp: $noTelp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TailorModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
