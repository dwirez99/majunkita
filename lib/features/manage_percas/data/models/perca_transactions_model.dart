/// Model untuk Perca Transactions (Transaksi Pengambilan Perca oleh Penjahit)
/// Menyimpan informasi tentang perca yang diambil oleh penjahit
class PercaTransactionsModel {
  final String? id;
  final String idStockPerca;
  final String idTailors;
  final DateTime dateEntry;
  final String percasType;
  final double weight;
  final String? staffId;
  final DateTime? createdAt;

  PercaTransactionsModel({
    this.id,
    required this.idStockPerca,
    required this.idTailors,
    required this.dateEntry,
    required this.percasType,
    required this.weight,
    this.staffId,
    this.createdAt,
  });

  /// Factory method untuk membuat PercaTransactionsModel dari JSON (Supabase response)
  factory PercaTransactionsModel.fromJson(Map<String, dynamic> json) {
    return PercaTransactionsModel(
      id: json['id'] as String?,
      idStockPerca: json['id_stock_perca'] as String? ?? '',
      idTailors: json['id_tailors'] as String? ?? '',
      dateEntry:
          json['date_entry'] != null
              ? DateTime.parse(json['date_entry'].toString())
              : DateTime.now(),
      percasType: json['percas_type'] as String? ?? '',
      weight: double.tryParse(json['weight']?.toString() ?? '0') ?? 0.0,
      staffId: json['staff_id'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'].toString())
              : null,
    );
  }

  /// Method untuk mengkonversi model ke JSON (untuk insert ke Supabase)
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id_stock_perca': idStockPerca,
      'id_tailors': idTailors,
      'date_entry': dateEntry.toIso8601String().split('T').first,
      'percas_type': percasType,
      'weight': weight,
    };

    // Hanya tambahkan id jika ada (untuk update)
    if (id != null) {
      map['id'] = id;
    }

    // Hanya tambahkan staff_id jika ada
    if (staffId != null) {
      map['staff_id'] = staffId;
    }

    return map;
  }

  /// Method untuk membuat copy dengan perubahan tertentu (immutable pattern)
  PercaTransactionsModel copyWith({
    String? id,
    String? idStockPerca,
    String? idTailors,
    DateTime? dateEntry,
    String? percasType,
    double? weight,
    String? staffId,
    DateTime? createdAt,
  }) {
    return PercaTransactionsModel(
      id: id ?? this.id,
      idStockPerca: idStockPerca ?? this.idStockPerca,
      idTailors: idTailors ?? this.idTailors,
      dateEntry: dateEntry ?? this.dateEntry,
      percasType: percasType ?? this.percasType,
      weight: weight ?? this.weight,
      staffId: staffId ?? this.staffId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'PercaTransactionsModel(id: $id, idTailors: $idTailors, percasType: $percasType, weight: $weight)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PercaTransactionsModel) return false;

    // Jika kedua objek memiliki id, gunakan id sebagai identitas utama
    if (id != null && other.id != null) {
      return id == other.id;
    }

    // Jika salah satu/both id null, bandingkan berdasarkan field lainnya
    return other.idStockPerca == idStockPerca &&
        other.idTailors == idTailors &&
        other.dateEntry == dateEntry &&
        other.percasType == percasType &&
        other.weight == weight &&
        other.staffId == staffId &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    // Jika id tersedia, gunakan sebagai sumber hash utama
    if (id != null) {
      return id.hashCode;
    }

    // Jika id null, gunakan kombinasi field lain untuk hashCode
    return Object.hash(
      idStockPerca,
      idTailors,
      dateEntry,
      percasType,
      weight,
      staffId,
      createdAt,
    );
  }
}
