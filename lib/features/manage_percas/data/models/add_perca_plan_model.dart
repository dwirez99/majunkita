/// Model untuk Rencana Pengambilan Perca (Procurement Plan)
/// Status: PENDING (baru dibuat), APPROVED (disetujui manager), REJECTED (ditolak manager)
class AddPercaPlanModel {
  final String id;
  final String idFactory;
  final DateTime plannedDate;
  final String status; // PENDING, APPROVED, REJECTED
  final String? notes; // Catatan penolakan atau keterangan lainnya
  final String createdBy; // ID user yang membuat rencana
  final DateTime createdAt;
  final DateTime updatedAt;

  AddPercaPlanModel({
    required this.id,
    required this.idFactory,
    required this.plannedDate,
    required this.status,
    this.notes,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory method untuk membuat AddPercaPlanModel dari JSON (Supabase response)
  factory AddPercaPlanModel.fromJson(Map<String, dynamic> json) {
    return AddPercaPlanModel(
      id: json['id'] as String? ?? '',
      idFactory: json['id_factory'] as String? ?? '',
      plannedDate: json['planned_date'] != null
          ? DateTime.parse(json['planned_date'] as String)
          : DateTime.now(),
      status: json['status'] as String? ?? 'PENDING',
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Method untuk mengkonversi AddPercaPlanModel ke JSON (untuk insert/update)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_factory': idFactory,
      'planned_date': plannedDate.toIso8601String().split('T')[0], // Format YYYY-MM-DD
      'status': status,
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Method untuk membuat copy dengan perubahan tertentu (immutable pattern)
  AddPercaPlanModel copyWith({
    String? id,
    String? idFactory,
    DateTime? plannedDate,
    String? status,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AddPercaPlanModel(
      id: id ?? this.id,
      idFactory: idFactory ?? this.idFactory,
      plannedDate: plannedDate ?? this.plannedDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AddPercaPlanModel(id: $id, idFactory: $idFactory, plannedDate: $plannedDate, status: $status, notes: $notes, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddPercaPlanModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          idFactory == other.idFactory &&
          plannedDate == other.plannedDate &&
          status == other.status &&
          notes == other.notes &&
          createdBy == other.createdBy &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      idFactory.hashCode ^
      plannedDate.hashCode ^
      status.hashCode ^
      notes.hashCode ^
      createdBy.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;
}