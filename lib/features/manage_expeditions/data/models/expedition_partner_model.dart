/// Model untuk mitra/perusahaan expedisi pengiriman (JNE, TIKI, SiCepat, dll).
/// Data disimpan di tabel `expedition_partners`, bukan di `profiles`.
class ExpeditionPartnerModel {
  final String id;
  final String name;
  final String? noTelp;
  final String? address;

  ExpeditionPartnerModel({
    required this.id,
    required this.name,
    this.noTelp,
    this.address,
  });

  factory ExpeditionPartnerModel.fromJson(Map<String, dynamic> json) {
    return ExpeditionPartnerModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Tanpa Nama',
      noTelp: json['no_telp'] as String?,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (noTelp != null) 'no_telp': noTelp,
      if (address != null) 'address': address,
    };
  }

  ExpeditionPartnerModel copyWith({
    String? id,
    String? name,
    String? noTelp,
    String? address,
  }) {
    return ExpeditionPartnerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      noTelp: noTelp ?? this.noTelp,
      address: address ?? this.address,
    );
  }

  @override
  String toString() => 'ExpeditionPartnerModel(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpeditionPartnerModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
