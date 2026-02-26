/// Model untuk data yang akan kita kirim ke tabel percas_stock
/// sack_code di-generate otomatis: K-{weight} untuk Kaos, B-{weight} untuk Kain
class PercasStock {
  final String idFactory;
  final DateTime dateEntry;
  final String percaType;
  final double weight;
  final String deliveryProof; // URL gambar setelah di-upload
  final String sackCode; // Kode karung: K-45, B-25, dll.

  PercasStock({
    required this.idFactory,
    required this.dateEntry,
    required this.percaType,
    required this.weight,
    required this.deliveryProof,
    required this.sackCode,
  });

  /// Generate sack_code otomatis dari jenis perca dan berat
  /// Kaos → K-{weight}, Kain → B-{weight}
  static String generateSackCode(String percaType, double weight) {
    final prefix = percaType.toLowerCase() == 'kaos' ? 'K' : 'B';
    // Bulatkan weight untuk kode (tanpa desimal jika bulat), dan
    // gunakan representasi desimal stabil untuk nilai non-integer.
    final weightStr =
        weight == weight.roundToDouble()
            ? weight.toInt().toString()
            : weight.toStringAsFixed(2);
    return '$prefix-$weightStr';
  }

  // Fungsi untuk mengubah objek menjadi Map/JSON untuk dikirim ke Supabase
  Map<String, dynamic> toJson() {
    return {
      'id_factory': idFactory,
      'date_entry': dateEntry.toIso8601String(),
      'perca_type': percaType,
      'weight': weight,
      'delivery_proof': deliveryProof,
      'sack_code': sackCode,
    };
  }
}
