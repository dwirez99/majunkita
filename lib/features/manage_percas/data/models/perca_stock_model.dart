// Model untuk data yang akan kita kirim ke tabel stok_perca
class PercasStock {
  final String idFactory;
  final DateTime dateEntry;
  final String percaType;
  final double weight;
  final String deliveryProof; // URL gambar setelah di-upload

  PercasStock({
    required this.idFactory,
    required this.dateEntry,
    required this.percaType,
    required this.weight,
    required this.deliveryProof,
  });

  // Fungsi untuk mengubah objek menjadi Map/JSON untuk dikirim ke Supabase
  Map<String, dynamic> toJson() {
    return {
      'id_factory': idFactory,
      'date_entry': dateEntry.toIso8601String(),
      'perca_type': percaType,
      'weight': weight,
      'delivery_proof': deliveryProof,
    };
  }
}