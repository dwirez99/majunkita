/// Model untuk Tailor (Penjahit)
/// Menyimpan informasi tentang penjahit yang mengolah limbah tekstil
class TailorModel {
  final String id;
  final String name;
  final String noTelp;
  final String address;
  final DateTime createdAt;
  final String? tailorImages;
  final double totalStock;
  final double balance;

  TailorModel({
    required this.id,
    required this.name,
    required this.noTelp,
    required this.address,
    required this.createdAt,
    this.tailorImages,
    this.totalStock = 0,
    this.balance = 0,
  });

  /// Factory method untuk membuat TailorModel dari JSON (Supabase response)
  /// Menggunakan safe null handling untuk menghindari runtime error
  factory TailorModel.fromJson(Map<String, dynamic> json) {
    return TailorModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      noTelp: json['no_telp'] as String? ?? '',
      address: json['address'] as String? ?? '',
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
      tailorImages: json['tailor_images'] as String?,
      totalStock: double.tryParse(json['total_stock']?.toString() ?? '0') ?? 0,
      balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0,
    );
  }

  /// Method untuk mengkonversi TailorModel ke JSON (untuk insert/update)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'no_telp': noTelp,
      'address': address,
      'tailor_images': tailorImages,
      // total_stock, balance, created_at are managed by the database
    };
  }

  /// Method untuk membuat copy dengan perubahan tertentu (immutable pattern)
  TailorModel copyWith({
    String? id,
    String? name,
    String? noTelp,
    String? address,
    DateTime? createdAt,
    String? tailorImages,
    double? totalStock,
    double? balance,
  }) {
    return TailorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      noTelp: noTelp ?? this.noTelp,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      tailorImages: tailorImages ?? this.tailorImages,
      totalStock: totalStock ?? this.totalStock,
      balance: balance ?? this.balance,
    );
  }

  @override
  String toString() {
    return 'TailorModel(id: $id, name: $name, noTelp: $noTelp, stock: $totalStock, balance: $balance)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TailorModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
