/// Model untuk data Factory
/// Menyimpan informasi tentang pabrik yang menyuplai limbah tekstil
class FactoryModel {
  final String id;
  final String factoryName;
  final String address;
  final String noTelp;

  FactoryModel({
    required this.id,
    required this.factoryName,
    required this.address,
    required this.noTelp,
  });

  /// Factory method untuk membuat FactoryModel dari JSON (Supabase response)
  /// Menggunakan safe null handling untuk menghindari runtime error
  factory FactoryModel.fromJson(Map<String, dynamic> json) {
    return FactoryModel(
      id: json['id'] as String? ?? '',
      factoryName: json['factory_name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      noTelp: json['no_telp'] as String? ?? '',
    );
  }

  /// Method untuk mengkonversi FactoryModel ke JSON (untuk insert/update)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'factory_name': factoryName,
      'address': address,
      'no_telp': noTelp,
    };
  }

  /// Method untuk membuat copy dengan perubahan tertentu (immutable pattern)
  FactoryModel copyWith({
    String? id,
    String? factoryName,
    String? address,
    String? noTelp,
  }) {
    return FactoryModel(
      id: id ?? this.id,
      factoryName: factoryName ?? this.factoryName,
      address: address ?? this.address,
      noTelp: noTelp ?? this.noTelp,
    );
  }

  @override
  String toString() {
    return 'FactoryModel(id: $id, factoryName: $factoryName, address: $address)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FactoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
