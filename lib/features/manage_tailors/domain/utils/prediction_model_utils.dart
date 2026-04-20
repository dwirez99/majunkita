/// Utility class untuk menghitung model prediksi produksi penjahit.
///
/// Rumus utama:
///   Reff = total_majun_disetor / total_perca_diambil
///         (0 jika total_perca_diambil == 0 untuk mencegah divide-by-zero)
///
///   Prediksi Majun = sisa_perca (S_current) × Reff
class PredictionModelUtils {
  const PredictionModelUtils._();

  /// Menghitung Rasio Efisiensi Historis (Reff).
  ///
  /// [totalMajunDisetor] – total berat majun yang sudah disetor penjahit.
  /// [totalPercaDiambil] – total berat perca yang pernah diambil penjahit.
  ///
  /// Mengembalikan 0.0 jika [totalPercaDiambil] <= 0 (penjahit baru atau
  /// belum ada riwayat pengambilan) untuk mencegah divide-by-zero.
  static double calculateReff({
    required double totalMajunDisetor,
    required double totalPercaDiambil,
  }) {
    if (totalPercaDiambil <= 0) return 0.0;
    return totalMajunDisetor / totalPercaDiambil;
  }

  /// Menghitung Prediksi Produksi Majun.
  ///
  /// [sisaPerca] – stok perca saat ini yang dipegang penjahit (S_current).
  /// [reff]      – Rasio Efisiensi Historis dari [calculateReff].
  ///
  /// Mengembalikan 0.0 jika [sisaPerca] atau [reff] adalah 0.
  static double calculatePrediksiMajun({
    required double sisaPerca,
    required double reff,
  }) {
    return sisaPerca * reff;
  }

  /// Menghitung statistik efisiensi secara lengkap dari satu pemanggilan.
  ///
  /// Mengembalikan map dengan kunci:
  ///   'reff'           – Rasio Efisiensi Historis
  ///   'prediksi_majun' – Prediksi produksi majun berdasarkan stok saat ini
  static Map<String, double> calculateEfficiencyStats({
    required double totalMajunDisetor,
    required double totalPercaDiambil,
    required double sisaPerca,
  }) {
    final reff = calculateReff(
      totalMajunDisetor: totalMajunDisetor,
      totalPercaDiambil: totalPercaDiambil,
    );
    final prediksiMajun = calculatePrediksiMajun(
      sisaPerca: sisaPerca,
      reff: reff,
    );
    return {
      'reff': reff,
      'prediksi_majun': prediksiMajun,
    };
  }
}
