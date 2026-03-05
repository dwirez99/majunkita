/// Model untuk Expedisi (Pengiriman barang)
/// Menyimpan informasi tentang pengiriman yang dilakukan oleh driver,
/// beserta mitra expedisi (perusahaan pengiriman) yang menanganinya.
class ExpeditionModel {
  final String id;
  final String idPartner;
  final DateTime expeditionDate;
  final String destination;
  final int sackNumber;
  final int totalWeight;
  final String proofOfDelivery;

  /// ID mitra expedisi (FK ke expedition_partners)
  final String? idExpeditionPartner;

  /// Nama driver dari tabel profiles (opsional, hasil JOIN)
  final String? partnerName;

  /// Nama mitra expedisi dari tabel expedition_partners (opsional, hasil JOIN)
  final String? expeditionPartnerName;

  ExpeditionModel({
    required this.id,
    required this.idPartner,
    required this.expeditionDate,
    required this.destination,
    required this.sackNumber,
    required this.totalWeight,
    required this.proofOfDelivery,
    this.idExpeditionPartner,
    this.partnerName,
    this.expeditionPartnerName,
  });

  /// Factory method untuk membuat ExpeditionModel dari JSON (Supabase response)
  /// Menggunakan safe null handling untuk menghindari runtime error
  factory ExpeditionModel.fromJson(Map<String, dynamic> json) {
    return ExpeditionModel(
      id: json['id'] as String? ?? '',
      idPartner: json['id_partner'] as String? ?? '',
      // Tanggal dari database berformat 'yyyy-MM-dd', parse ke DateTime
      expeditionDate: json['expedition_date'] != null
          ? DateTime.parse(json['expedition_date'] as String)
          : DateTime.now(),
      destination: json['destination'] as String? ?? '',
      // Konversi integer dengan aman dari berbagai tipe data
      sackNumber: (json['sack_number'] as num?)?.toInt() ?? 0,
      totalWeight: (json['total_weight'] as num?)?.toInt() ?? 0,
      proofOfDelivery: json['proof_of_delivery'] as String? ?? '',
      idExpeditionPartner: json['id_expedition_partner'] as String?,
      // Ambil nama driver dari hasil JOIN dengan tabel profiles
      partnerName: json['profiles'] != null
          ? (json['profiles'] as Map<String, dynamic>)['name'] as String?
          : null,
      // Ambil nama mitra expedisi dari hasil JOIN dengan tabel expedition_partners
      expeditionPartnerName: json['expedition_partners'] != null
          ? (json['expedition_partners'] as Map<String, dynamic>)['name']
              as String?
          : null,
    );
  }

  /// Method untuk mengkonversi ExpeditionModel ke JSON (untuk insert/update)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_partner': idPartner,
      // Format tanggal ke 'yyyy-MM-dd' sesuai tipe date di PostgreSQL
      'expedition_date':
          '${expeditionDate.year.toString().padLeft(4, '0')}-'
          '${expeditionDate.month.toString().padLeft(2, '0')}-'
          '${expeditionDate.day.toString().padLeft(2, '0')}',
      'destination': destination,
      'sack_number': sackNumber,
      'total_weight': totalWeight,
      'proof_of_delivery': proofOfDelivery,
      if (idExpeditionPartner != null)
        'id_expedition_partner': idExpeditionPartner,
    };
  }

  /// Method untuk membuat copy dengan perubahan tertentu (immutable pattern)
  ExpeditionModel copyWith({
    String? id,
    String? idPartner,
    DateTime? expeditionDate,
    String? destination,
    int? sackNumber,
    int? totalWeight,
    String? proofOfDelivery,
    String? idExpeditionPartner,
    String? partnerName,
    String? expeditionPartnerName,
  }) {
    return ExpeditionModel(
      id: id ?? this.id,
      idPartner: idPartner ?? this.idPartner,
      expeditionDate: expeditionDate ?? this.expeditionDate,
      destination: destination ?? this.destination,
      sackNumber: sackNumber ?? this.sackNumber,
      totalWeight: totalWeight ?? this.totalWeight,
      proofOfDelivery: proofOfDelivery ?? this.proofOfDelivery,
      idExpeditionPartner: idExpeditionPartner ?? this.idExpeditionPartner,
      partnerName: partnerName ?? this.partnerName,
      expeditionPartnerName:
          expeditionPartnerName ?? this.expeditionPartnerName,
    );
  }

  @override
  String toString() {
    return 'ExpeditionModel(id: $id, destination: $destination, date: $expeditionDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpeditionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
