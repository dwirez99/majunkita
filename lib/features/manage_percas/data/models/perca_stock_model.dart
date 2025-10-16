// Model untuk data yang akan kita kirim ke tabel stok_perca
class PercaStock {
  final String idPabrik;
  final DateTime tglMasuk;
  final String jenis;
  final double berat;
  final String buktiAmbilUrl; // URL gambar setelah di-upload

  PercaStock({
    required this.idPabrik,
    required this.tglMasuk,
    required this.jenis,
    required this.berat,
    required this.buktiAmbilUrl,
  });

  // Fungsi untuk mengubah objek menjadi Map/JSON untuk dikirim ke Supabase
  Map<String, dynamic> toJson() {
    return {
      'id_pabrik': idPabrik,
      'tgl_masuk': tglMasuk.toIso8601String(),
      'jenis': jenis,
      'berat': berat,
      'bukti_ambil': buktiAmbilUrl,
    };
  }
}