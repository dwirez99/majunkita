// lib/features/dashboard/data/models/admin_dashboard_models.dart
import 'package:intl/intl.dart';

// ── Formatters (shared) ───────────────────────────────────────────────────

final _currency = NumberFormat.currency(
    locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
final _weight = NumberFormat('#,##0.##', 'id_ID');

String _fmt(num v) => _weight.format(v);
String _rp(num v) => _currency.format(v);
num _n(dynamic v) => num.tryParse(v?.toString() ?? '0') ?? 0;

// ── Root model ────────────────────────────────────────────────────────────

class AdminDashboardSummary {
  final PercaSummary perca;
  final MajunSummary majun;
  final ExpedisiSummary expedisi;
  final TailorSummary penjahit;
  final LimbahSummary limbah;

  const AdminDashboardSummary({
    required this.perca,
    required this.majun,
    required this.expedisi,
    required this.penjahit,
    required this.limbah,
  });

  factory AdminDashboardSummary.fromJson(Map<String, dynamic> json) {
    return AdminDashboardSummary(
      perca: PercaSummary.fromJson(
          (json['perca'] as Map<String, dynamic>?) ?? {}),
      majun: MajunSummary.fromJson(
          (json['majun'] as Map<String, dynamic>?) ?? {}),
      expedisi: ExpedisiSummary.fromJson(
          (json['expedisi'] as Map<String, dynamic>?) ?? {}),
      penjahit: TailorSummary.fromJson(
          (json['penjahit'] as Map<String, dynamic>?) ?? {}),
      limbah: LimbahSummary.fromJson(
          (json['limbah'] as Map<String, dynamic>?) ?? {}),
    );
  }
}

// ── Perca ─────────────────────────────────────────────────────────────────

class PercaSummary {
  /// Stok perca di gudang pabrik (percas_stock)
  final num stokGudang;

  /// Total perca yang sudah diberikan ke penjahit
  final num totalDiberikanKePenjahit;

  /// Perca yang didistribusikan bulan ini
  final num distribusiBulanIni;

  const PercaSummary({
    required this.stokGudang,
    required this.totalDiberikanKePenjahit,
    required this.distribusiBulanIni,
  });

  String get fmtStokGudang => '${_fmt(stokGudang)} kg';
  String get fmtTotalDiberikan => '${_fmt(totalDiberikanKePenjahit)} kg';
  String get fmtDistribusiBulanIni => '${_fmt(distribusiBulanIni)} kg';

  factory PercaSummary.fromJson(Map<String, dynamic> json) => PercaSummary(
        stokGudang: _n(json['stok_gudang']),
        totalDiberikanKePenjahit: _n(json['total_diberikan_ke_penjahit']),
        distribusiBulanIni: _n(json['distribusi_bulan_ini']),
      );
}

// ── Majun ─────────────────────────────────────────────────────────────────

class MajunSummary {
  /// Total majun diterima dari penjahit (majun_transactions)
  final num totalDiterima;

  /// Total majun sudah dikirim via expedisi
  final num totalTerkirim;

  /// Stok efektif saat ini = totalDiterima - totalTerkirim
  final num stokEfektif;

  /// Total upah yang sudah dibayarkan
  final num totalUpahDibayar;

  /// Majun diterima bulan ini
  final num diterimaBulanIni;

  const MajunSummary({
    required this.totalDiterima,
    required this.totalTerkirim,
    required this.stokEfektif,
    required this.totalUpahDibayar,
    required this.diterimaBulanIni,
  });

  String get fmtTotalDiterima => '${_fmt(totalDiterima)} kg';
  String get fmtTotalTerkirim => '${_fmt(totalTerkirim)} kg';
  String get fmtStokEfektif => '${_fmt(stokEfektif)} kg';
  String get fmtTotalUpah => _rp(totalUpahDibayar);
  String get fmtDiterimaBulanIni => '${_fmt(diterimaBulanIni)} kg';

  factory MajunSummary.fromJson(Map<String, dynamic> json) => MajunSummary(
        totalDiterima: _n(json['total_diterima']),
        totalTerkirim: _n(json['total_terkirim']),
        stokEfektif: _n(json['stok_efektif']),
        totalUpahDibayar: _n(json['total_upah_dibayar']),
        diterimaBulanIni: _n(json['diterima_bulan_ini']),
      );
}

// ── Expedisi ──────────────────────────────────────────────────────────────

class ExpedisiSummary {
  /// Total pengiriman sepanjang waktu
  final int totalPengiriman;

  /// Total karung yang dikirim
  final int totalKarung;

  /// Total berat yang dikirim (kg)
  final num totalBeratKg;

  /// Pengiriman bulan ini
  final int pengirimanBulanIni;

  /// Berat yang dikirim bulan ini
  final num beratBulanIni;

  const ExpedisiSummary({
    required this.totalPengiriman,
    required this.totalKarung,
    required this.totalBeratKg,
    required this.pengirimanBulanIni,
    required this.beratBulanIni,
  });

  String get fmtTotalBerat => '${_fmt(totalBeratKg)} kg';
  String get fmtBeratBulanIni => '${_fmt(beratBulanIni)} kg';

  factory ExpedisiSummary.fromJson(Map<String, dynamic> json) =>
      ExpedisiSummary(
        totalPengiriman: _n(json['total_pengiriman']).toInt(),
        totalKarung: _n(json['total_karung']).toInt(),
        totalBeratKg: _n(json['total_berat_kg']),
        pengirimanBulanIni: _n(json['pengiriman_bulan_ini']).toInt(),
        beratBulanIni: _n(json['berat_bulan_ini']),
      );
}

// ── Penjahit ──────────────────────────────────────────────────────────────

class TailorSummary {
  /// Jumlah penjahit terdaftar
  final int jumlahAktif;

  /// Total stok perca yang dipegang penjahit (tailors.total_stock)
  final num totalStokPenjahit;

  /// Total saldo belum ditarik (tailors.balance)
  final num totalSaldoBelumDitarik;

  const TailorSummary({
    required this.jumlahAktif,
    required this.totalStokPenjahit,
    required this.totalSaldoBelumDitarik,
  });

  String get fmtTotalStok => '${_fmt(totalStokPenjahit)} kg';
  String get fmtSaldoBelumDitarik => _rp(totalSaldoBelumDitarik);

  // Keep old getter name for any existing code
  String get formattedUnpaidWages => fmtSaldoBelumDitarik;

  factory TailorSummary.fromJson(Map<String, dynamic> json) => TailorSummary(
        jumlahAktif: _n(json['jumlah_aktif']).toInt(),
        totalStokPenjahit: _n(json['total_stok_penjahit']),
        totalSaldoBelumDitarik: _n(json['total_saldo_belum_ditarik']),
      );
}

// ── Limbah ────────────────────────────────────────────────────────────────

class LimbahSummary {
  /// Total limbah diterima sepanjang waktu
  final num totalDiterima;

  /// Limbah diterima bulan ini
  final num diterimaBulanIni;

  const LimbahSummary({
    required this.totalDiterima,
    required this.diterimaBulanIni,
  });

  String get fmtTotalDiterima => '${_fmt(totalDiterima)} kg';
  String get fmtDiterimaBulanIni => '${_fmt(diterimaBulanIni)} kg';

  factory LimbahSummary.fromJson(Map<String, dynamic> json) => LimbahSummary(
        totalDiterima: _n(json['total_diterima']),
        diterimaBulanIni: _n(json['diterima_bulan_ini']),
      );
}