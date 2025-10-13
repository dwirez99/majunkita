// lib/features/dashboard/data/models/admin_dashboard_model.dart
import 'package:intl/intl.dart';

// Model utama yang menampung semua data
class AdminDashboardSummary {
  final PercaSummary percaSummary;
  final num stockAtTailor; // Stok perca di penjahit
  final MajunSummary majunSummary;
  final TailorSummary tailorSummary;

  AdminDashboardSummary({
    required this.percaSummary,
    required this.stockAtTailor,
    required this.majunSummary,
    required this.tailorSummary,
  });

  // Factory constructor untuk mengubah JSON dari Supabase menjadi objek Dart
  factory AdminDashboardSummary.fromJson(Map<String, dynamic> json) {
    return AdminDashboardSummary(
      percaSummary: PercaSummary.fromJson(json['perca']),
      stockAtTailor: json['stok_di_penjahit'] ?? 0,
      majunSummary: MajunSummary.fromJson(json['majun']),
      tailorSummary: TailorSummary.fromJson(json['penjahit']),
    );
  }
}

// Sub-model untuk Perca
class PercaSummary {
  final num stockSaatIni;

  PercaSummary({required this.stockSaatIni});

  factory PercaSummary.fromJson(Map<String, dynamic> json) {
    return PercaSummary(stockSaatIni: json['stock_saat_ini'] ?? 0);
  }
}

// Sub-model untuk Majun
class MajunSummary {
  final num stockSaatIni;

  MajunSummary({required this.stockSaatIni});

  factory MajunSummary.fromJson(Map<String, dynamic> json) {
    return MajunSummary(stockSaatIni: json['stock_saat_ini'] ?? 0);
  }
}

// Sub-model untuk Penjahit
class TailorSummary {
  final int jumlahAktif;
  final num upahBelumDibayar;

  TailorSummary({required this.jumlahAktif, required this.upahBelumDibayar});

  // Helper untuk format mata uang
  String get formattedUnpaidWages {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(upahBelumDibayar);
  }

  factory TailorSummary.fromJson(Map<String, dynamic> json) {
    return TailorSummary(
      jumlahAktif: json['jumlah_aktif'] ?? 0,
      upahBelumDibayar: json['upah_belum_dibayar'] ?? 0,
    );
  }
}