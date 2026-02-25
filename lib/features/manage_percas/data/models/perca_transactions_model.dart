class PercaTransactionsModel {
  final String id;
  final String idPercaStock;
  final String idTransactionPerca;
  final String idTailor;
  final DateTime dateEntry;
  final String percaType;
  final double weight;

  PercaTransactionsModel({
    required this.id,
    required this.idPercaStock,
    required this.idTransactionPerca,
    required this.idTailor,
    required this.dateEntry,
    required this.percaType,
    required this.weight,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_perca_stock': idPercaStock,
      'id_transaction_perca': idTransactionPerca,
      'id_tailor': idTailor,
      'date_entry': dateEntry.toIso8601String(),
      'perca_type': percaType,
      'weight': weight,
    };
  }
}
