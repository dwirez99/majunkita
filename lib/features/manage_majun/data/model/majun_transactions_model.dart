/// Model untuk Majun Transactions (Setoran Lap Majun dari Penjahit)
/// Matches DB schema: majun_transactions table
/// Trigger auto menghitung earned_wage & update tailors.total_stock/balance
class MajunTransactionsModel {
  final String? id;
  final String idTailor;
  final DateTime dateEntry;
  final double weightMajun;
  final double earnedWage;
  final String? staffId;
  final String? deliveryProof;
  final DateTime? createdAt;

  // Joined field (dari RPC rpc_get_majun_history)
  final String? tailorName;

  MajunTransactionsModel({
    this.id,
    required this.idTailor,
    required this.dateEntry,
    required this.weightMajun,
    this.earnedWage = 0,
    this.staffId,
    this.deliveryProof,
    this.createdAt,
    this.tailorName,
  });

  factory MajunTransactionsModel.fromJson(Map<String, dynamic> json) {
    return MajunTransactionsModel(
      id: json['id']?.toString(),
      idTailor: json['id_tailor'] as String? ?? '',
      dateEntry:
          json['date_entry'] != null
              ? DateTime.parse(json['date_entry'].toString())
              : DateTime.now(),
      weightMajun:
          double.tryParse(json['weight_majun']?.toString() ?? '0') ?? 0.0,
      earnedWage:
          double.tryParse(json['earned_wage']?.toString() ?? '0') ?? 0.0,
      staffId: json['staff_id'] as String?,
      deliveryProof: json['delivery_proof'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString())
              : null,
      tailorName: json['tailor_name'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson() {
    final map = <String, dynamic>{
      'id_tailor': idTailor,
      'date_entry': dateEntry.toIso8601String().split('T').first,
      'weight_majun': weightMajun,
    };
    if (staffId != null) map['staff_id'] = staffId;
    if (deliveryProof != null) map['delivery_proof'] = deliveryProof;
    return map;
  }

  @override
  String toString() =>
      'MajunTransactionsModel(id: $id, idTailor: $idTailor, weightMajun: $weightMajun, earnedWage: $earnedWage)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MajunTransactionsModel) return false;
    if (id != null && other.id != null) return id == other.id;
    return other.idTailor == idTailor &&
        other.dateEntry == dateEntry &&
        other.weightMajun == weightMajun;
  }

  @override
  int get hashCode {
    if (id != null) return id.hashCode;
    return Object.hash(idTailor, dateEntry, weightMajun);
  }
}

/// Model untuk Limbah Transactions (Setoran Limbah dari Penjahit)
/// Matches DB schema: limbah_transactions table
/// Trigger auto mengurangi tailors.total_stock TANPA menambah upah.
class LimbahTransactionsModel {
  final String? id;
  final String idTailor;
  final DateTime dateEntry;
  final double weightLimbah;
  final String? staffId;
  final String? deliveryProof;
  final DateTime? createdAt;

  // Joined field (dari RPC rpc_get_limbah_history)
  final String? tailorName;

  LimbahTransactionsModel({
    this.id,
    required this.idTailor,
    required this.dateEntry,
    required this.weightLimbah,
    this.staffId,
    this.deliveryProof,
    this.createdAt,
    this.tailorName,
  });

  factory LimbahTransactionsModel.fromJson(Map<String, dynamic> json) {
    return LimbahTransactionsModel(
      id: json['id']?.toString(),
      idTailor: json['id_tailor'] as String? ?? '',
      dateEntry:
          json['date_entry'] != null
              ? DateTime.parse(json['date_entry'].toString())
              : DateTime.now(),
      weightLimbah:
          double.tryParse(json['weight_limbah']?.toString() ?? '0') ?? 0.0,
      staffId: json['staff_id'] as String?,
      deliveryProof: json['delivery_proof'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString())
              : null,
      tailorName: json['tailor_name'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson() {
    final map = <String, dynamic>{
      'id_tailor': idTailor,
      'date_entry': dateEntry.toIso8601String().split('T').first,
      'weight_limbah': weightLimbah,
    };
    if (staffId != null) map['staff_id'] = staffId;
    if (deliveryProof != null) map['delivery_proof'] = deliveryProof;
    return map;
  }

  @override
  String toString() =>
      'LimbahTransactionsModel(id: $id, idTailor: $idTailor, weightLimbah: $weightLimbah)';
}

/// Model untuk response insert majun_transactions
/// Setelah INSERT, trigger sudah menghitung earned_wage otomatis
class SetorMajunResult {
  final String transactionId;
  final double weightMajun;
  final double earnedWage;

  SetorMajunResult({
    required this.transactionId,
    required this.weightMajun,
    required this.earnedWage,
  });

  factory SetorMajunResult.fromJson(Map<String, dynamic> json) {
    return SetorMajunResult(
      transactionId: json['id']?.toString() ?? '',
      weightMajun:
          double.tryParse(json['weight_majun']?.toString() ?? '0') ?? 0.0,
      earnedWage:
          double.tryParse(json['earned_wage']?.toString() ?? '0') ?? 0.0,
    );
  }
}
