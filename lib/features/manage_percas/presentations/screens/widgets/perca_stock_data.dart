/// Strongly-typed data class untuk visualisasi chart perca.
/// Menggantikan Map yang rapuh (magic string keys).
class PercaStockData {
  final DateTime period; // Bulan & tahun periode data
  final double total;    // Total berat (kain + kaos)
  final double kain;     // Berat kain saja
  final double kaos;     // Berat kaos saja

  const PercaStockData({
    required this.period,
    required this.total,
    required this.kain,
    required this.kaos,
  });

  /// Buat PercaStockData dari raw map provider (key: 'YYYY-MM').
  factory PercaStockData.fromMapEntry(String monthKey, Map<String, double> values) {
    final parts = monthKey.split('-');
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = int.tryParse(parts.length > 1 ? parts[1] : '1') ?? 1;
    final kain = values['kain'] ?? 0.0;
    final kaos = values['kaos'] ?? 0.0;
    return PercaStockData(
      period: DateTime(year, month),
      total: values['total'] ?? (kain + kaos),
      kain: kain,
      kaos: kaos,
    );
  }

  /// Label singkat untuk sumbu X (e.g. "Jan\n24").
  String get shortLabel {
    const names = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
                   'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final y = period.year.toString().substring(2);
    return '${names[period.month]}\n$y';
  }

  /// Label panjang untuk filter chip (e.g. "Jan 2024").
  String get longLabel {
    const names = ['', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
                   'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return '${names[period.month]} ${period.year}';
  }

  /// Key unik YYYY-MM untuk identifikasi.
  String get monthKey =>
      '${period.year}-${period.month.toString().padLeft(2, '0')}';

  @override
  String toString() =>
      'PercaStockData(period: $monthKey, total: $total, kain: $kain, kaos: $kaos)';
}

/// Enum untuk rentang waktu filter (digunakan Line & Bar Chart).
enum DateRangeFilter {
  last3Months('3 Bulan', 3),
  last6Months('6 Bulan', 6),
  last12Months('12 Bulan', 12);

  final String label;
  final int months;
  const DateRangeFilter(this.label, this.months);
}
