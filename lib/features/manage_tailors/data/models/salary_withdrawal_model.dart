class SalaryWithdrawalModel {
  final int id;
  final DateTime createdAt;
  final String idTailor;
  final double amount;
  final DateTime dateEntry;

  SalaryWithdrawalModel({
    required this.id,
    required this.createdAt,
    required this.idTailor,
    required this.amount,
    required this.dateEntry,
  });

  factory SalaryWithdrawalModel.fromJson(Map<String, dynamic> json) {
    return SalaryWithdrawalModel(
      id: json['id'] as int? ?? 0,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'].toString())
              : DateTime.now(),
      idTailor: json['id_tailor'] as String? ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      dateEntry:
          json['date_entry'] != null
              ? DateTime.parse(json['date_entry'].toString())
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_tailor': idTailor,
      'amount': amount,
      'date_entry': dateEntry.toIso8601String().split('T')[0],
      // id and created_at are usually managed by the database on insert
    };
  }

  SalaryWithdrawalModel copyWith({
    int? id,
    DateTime? createdAt,
    String? idTailor,
    double? amount,
    DateTime? dateEntry,
  }) {
    return SalaryWithdrawalModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      idTailor: idTailor ?? this.idTailor,
      amount: amount ?? this.amount,
      dateEntry: dateEntry ?? this.dateEntry,
    );
  }

  @override
  String toString() {
    return 'SalaryWithdrawalModel(id: $id, idTailor: $idTailor, amount: $amount, dateEntry: $dateEntry)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SalaryWithdrawalModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
