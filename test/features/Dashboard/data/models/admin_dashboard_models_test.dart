import 'package:flutter_test/flutter_test.dart';
import 'package:majunkita/features/Dashboard/data/models/admin_dashboard_models.dart';

void main() {
  group('PercaSummary', () {
    const testStokGudang = 1000;
    const testTotalDiberikan = 500;
    const testDistribusiBulanIni = 100;

    final testJson = {
      'stok_gudang': testStokGudang,
      'total_diberikan_ke_penjahit': testTotalDiberikan,
      'distribusi_bulan_ini': testDistribusiBulanIni,
    };

    late PercaSummary testSummary;

    setUp(() {
      testSummary = const PercaSummary(
        stokGudang: testStokGudang,
        totalDiberikanKePenjahit: testTotalDiberikan,
        distribusiBulanIni: testDistribusiBulanIni,
      );
    });

    group('Constructor', () {
      test('should create PercaSummary with all fields', () {
        expect(testSummary.stokGudang, testStokGudang);
        expect(testSummary.totalDiberikanKePenjahit, testTotalDiberikan);
        expect(testSummary.distribusiBulanIni, testDistribusiBulanIni);
      });
    });

    group('fromJson', () {
      test('should parse valid JSON correctly', () {
        final summary = PercaSummary.fromJson(testJson);
        expect(summary.stokGudang, testStokGudang);
        expect(summary.totalDiberikanKePenjahit, testTotalDiberikan);
        expect(summary.distribusiBulanIni, testDistribusiBulanIni);
      });

      test('should handle missing fields with zero values', () {
        final summary = PercaSummary.fromJson({});
        expect(summary.stokGudang, 0);
        expect(summary.totalDiberikanKePenjahit, 0);
        expect(summary.distribusiBulanIni, 0);
      });

      test('should parse string values as numbers', () {
        final summary = PercaSummary.fromJson({
          'stok_gudang': '1500',
          'total_diberikan_ke_penjahit': '750',
          'distribusi_bulan_ini': '150',
        });
        expect(summary.stokGudang, 1500);
        expect(summary.totalDiberikanKePenjahit, 750);
        expect(summary.distribusiBulanIni, 150);
      });
    });

    group('Formatted getters', () {
      test('fmtStokGudang should format with kg unit', () {
        final formatted = testSummary.fmtStokGudang;
        expect(formatted, contains('kg'));
        expect(formatted, contains('1'));
      });

      test('fmtTotalDiberikan should format with kg unit', () {
        final formatted = testSummary.fmtTotalDiberikan;
        expect(formatted, contains('kg'));
      });

      test('fmtDistribusiBulanIni should format with kg unit', () {
        final formatted = testSummary.fmtDistribusiBulanIni;
        expect(formatted, contains('kg'));
      });
    });
  });

  group('MajunSummary', () {
    const testTotalDiterima = 5000;
    const testTotalTerkirim = 3000;
    const testStokEfektif = 2000;
    const testTotalUpahDibayar = 100000;
    const testDiterimaBulanIni = 500;

    final testJson = {
      'total_diterima': testTotalDiterima,
      'total_terkirim': testTotalTerkirim,
      'stok_efektif': testStokEfektif,
      'total_upah_dibayar': testTotalUpahDibayar,
      'diterima_bulan_ini': testDiterimaBulanIni,
    };

    late MajunSummary testSummary;

    setUp(() {
      testSummary = const MajunSummary(
        totalDiterima: testTotalDiterima,
        totalTerkirim: testTotalTerkirim,
        stokEfektif: testStokEfektif,
        totalUpahDibayar: testTotalUpahDibayar,
        diterimaBulanIni: testDiterimaBulanIni,
      );
    });

    group('Constructor', () {
      test('should create MajunSummary with all fields', () {
        expect(testSummary.totalDiterima, testTotalDiterima);
        expect(testSummary.totalTerkirim, testTotalTerkirim);
        expect(testSummary.stokEfektif, testStokEfektif);
        expect(testSummary.totalUpahDibayar, testTotalUpahDibayar);
        expect(testSummary.diterimaBulanIni, testDiterimaBulanIni);
      });
    });

    group('fromJson', () {
      test('should parse valid JSON correctly', () {
        final summary = MajunSummary.fromJson(testJson);
        expect(summary.totalDiterima, testTotalDiterima);
        expect(summary.totalTerkirim, testTotalTerkirim);
        expect(summary.stokEfektif, testStokEfektif);
        expect(summary.totalUpahDibayar, testTotalUpahDibayar);
        expect(summary.diterimaBulanIni, testDiterimaBulanIni);
      });

      test('should handle missing fields with zero values', () {
        final summary = MajunSummary.fromJson({});
        expect(summary.totalDiterima, 0);
        expect(summary.totalTerkirim, 0);
        expect(summary.stokEfektif, 0);
        expect(summary.totalUpahDibayar, 0);
        expect(summary.diterimaBulanIni, 0);
      });
    });

    group('Formatted getters', () {
      test('fmtTotalDiterima should format with kg unit', () {
        final formatted = testSummary.fmtTotalDiterima;
        expect(formatted, contains('kg'));
      });

      test('fmtTotalTerkirim should format with kg unit', () {
        final formatted = testSummary.fmtTotalTerkirim;
        expect(formatted, contains('kg'));
      });

      test('fmtStokEfektif should format with kg unit', () {
        final formatted = testSummary.fmtStokEfektif;
        expect(formatted, contains('kg'));
      });

      test('fmtTotalUpah should format as Rupiah', () {
        final formatted = testSummary.fmtTotalUpah;
        expect(formatted, contains('Rp'));
      });

      test('fmtDiterimaBulanIni should format with kg unit', () {
        final formatted = testSummary.fmtDiterimaBulanIni;
        expect(formatted, contains('kg'));
      });
    });
  });

  group('ExpedisiSummary', () {
    const testTotalPengiriman = 50;
    const testTotalKarung = 1000;
    const testTotalBeratKg = 50000;
    const testPengirimanBulanIni = 10;
    const testBeratBulanIni = 5000;

    final testJson = {
      'total_pengiriman': testTotalPengiriman,
      'total_karung': testTotalKarung,
      'total_berat_kg': testTotalBeratKg,
      'pengiriman_bulan_ini': testPengirimanBulanIni,
      'berat_bulan_ini': testBeratBulanIni,
    };

    late ExpedisiSummary testSummary;

    setUp(() {
      testSummary = const ExpedisiSummary(
        totalPengiriman: testTotalPengiriman,
        totalKarung: testTotalKarung,
        totalBeratKg: testTotalBeratKg,
        pengirimanBulanIni: testPengirimanBulanIni,
        beratBulanIni: testBeratBulanIni,
      );
    });

    group('Constructor', () {
      test('should create ExpedisiSummary with all fields', () {
        expect(testSummary.totalPengiriman, testTotalPengiriman);
        expect(testSummary.totalKarung, testTotalKarung);
        expect(testSummary.totalBeratKg, testTotalBeratKg);
        expect(testSummary.pengirimanBulanIni, testPengirimanBulanIni);
        expect(testSummary.beratBulanIni, testBeratBulanIni);
      });
    });

    group('fromJson', () {
      test('should parse valid JSON correctly', () {
        final summary = ExpedisiSummary.fromJson(testJson);
        expect(summary.totalPengiriman, testTotalPengiriman);
        expect(summary.totalKarung, testTotalKarung);
        expect(summary.totalBeratKg, testTotalBeratKg);
        expect(summary.pengirimanBulanIni, testPengirimanBulanIni);
        expect(summary.beratBulanIni, testBeratBulanIni);
      });

      test('should convert to int for integer fields', () {
        final summary = ExpedisiSummary.fromJson({
          'total_pengiriman': 50.5,
          'total_karung': 1000.9,
          'pengiriman_bulan_ini': 10.7,
          'total_berat_kg': 50000,
          'berat_bulan_ini': 5000,
        });
        expect(summary.totalPengiriman, isA<int>());
        expect(summary.totalKarung, isA<int>());
        expect(summary.pengirimanBulanIni, isA<int>());
      });

      test('should handle missing fields with zero values', () {
        final summary = ExpedisiSummary.fromJson({});
        expect(summary.totalPengiriman, 0);
        expect(summary.totalKarung, 0);
        expect(summary.totalBeratKg, 0);
        expect(summary.pengirimanBulanIni, 0);
        expect(summary.beratBulanIni, 0);
      });
    });

    group('Formatted getters', () {
      test('fmtTotalBerat should format with kg unit', () {
        final formatted = testSummary.fmtTotalBerat;
        expect(formatted, contains('kg'));
      });

      test('fmtBeratBulanIni should format with kg unit', () {
        final formatted = testSummary.fmtBeratBulanIni;
        expect(formatted, contains('kg'));
      });
    });
  });

  group('TailorSummary', () {
    const testJumlahAktif = 25;
    const testTotalStokPenjahit = 2500;
    const testTotalSaldoBelumDitarik = 500000;

    final testJson = {
      'jumlah_aktif': testJumlahAktif,
      'total_stok_penjahit': testTotalStokPenjahit,
      'total_saldo_belum_ditarik': testTotalSaldoBelumDitarik,
    };

    late TailorSummary testSummary;

    setUp(() {
      testSummary = const TailorSummary(
        jumlahAktif: testJumlahAktif,
        totalStokPenjahit: testTotalStokPenjahit,
        totalSaldoBelumDitarik: testTotalSaldoBelumDitarik,
      );
    });

    group('Constructor', () {
      test('should create TailorSummary with all fields', () {
        expect(testSummary.jumlahAktif, testJumlahAktif);
        expect(testSummary.totalStokPenjahit, testTotalStokPenjahit);
        expect(testSummary.totalSaldoBelumDitarik, testTotalSaldoBelumDitarik);
      });
    });

    group('fromJson', () {
      test('should parse valid JSON correctly', () {
        final summary = TailorSummary.fromJson(testJson);
        expect(summary.jumlahAktif, testJumlahAktif);
        expect(summary.totalStokPenjahit, testTotalStokPenjahit);
        expect(summary.totalSaldoBelumDitarik, testTotalSaldoBelumDitarik);
      });

      test('should handle missing fields with zero values', () {
        final summary = TailorSummary.fromJson({});
        expect(summary.jumlahAktif, 0);
        expect(summary.totalStokPenjahit, 0);
        expect(summary.totalSaldoBelumDitarik, 0);
      });
    });

    group('Formatted getters', () {
      test('fmtTotalStok should format with kg unit', () {
        final formatted = testSummary.fmtTotalStok;
        expect(formatted, contains('kg'));
      });

      test('fmtSaldoBelumDitarik should format as Rupiah', () {
        final formatted = testSummary.fmtSaldoBelumDitarik;
        expect(formatted, contains('Rp'));
      });

      test('formattedUnpaidWages should return same as fmtSaldoBelumDitarik', () {
        expect(testSummary.formattedUnpaidWages, testSummary.fmtSaldoBelumDitarik);
      });
    });
  });

  group('LimbahSummary', () {
    const testTotalDiterima = 3000;
    const testDiterimaBulanIni = 300;

    final testJson = {
      'total_diterima': testTotalDiterima,
      'diterima_bulan_ini': testDiterimaBulanIni,
    };

    late LimbahSummary testSummary;

    setUp(() {
      testSummary = const LimbahSummary(
        totalDiterima: testTotalDiterima,
        diterimaBulanIni: testDiterimaBulanIni,
      );
    });

    group('Constructor', () {
      test('should create LimbahSummary with all fields', () {
        expect(testSummary.totalDiterima, testTotalDiterima);
        expect(testSummary.diterimaBulanIni, testDiterimaBulanIni);
      });
    });

    group('fromJson', () {
      test('should parse valid JSON correctly', () {
        final summary = LimbahSummary.fromJson(testJson);
        expect(summary.totalDiterima, testTotalDiterima);
        expect(summary.diterimaBulanIni, testDiterimaBulanIni);
      });

      test('should handle missing fields with zero values', () {
        final summary = LimbahSummary.fromJson({});
        expect(summary.totalDiterima, 0);
        expect(summary.diterimaBulanIni, 0);
      });
    });

    group('Formatted getters', () {
      test('fmtTotalDiterima should format with kg unit', () {
        final formatted = testSummary.fmtTotalDiterima;
        expect(formatted, contains('kg'));
      });

      test('fmtDiterimaBulanIni should format with kg unit', () {
        final formatted = testSummary.fmtDiterimaBulanIni;
        expect(formatted, contains('kg'));
      });
    });
  });

  group('AdminDashboardSummary', () {
    final testJson = {
      'perca': {
        'stok_gudang': 1000,
        'total_diberikan_ke_penjahit': 500,
        'distribusi_bulan_ini': 100,
      },
      'majun': {
        'total_diterima': 5000,
        'total_terkirim': 3000,
        'stok_efektif': 2000,
        'total_upah_dibayar': 100000,
        'diterima_bulan_ini': 500,
      },
      'expedisi': {
        'total_pengiriman': 50,
        'total_karung': 1000,
        'total_berat_kg': 50000,
        'pengiriman_bulan_ini': 10,
        'berat_bulan_ini': 5000,
      },
      'penjahit': {
        'jumlah_aktif': 25,
        'total_stok_penjahit': 2500,
        'total_saldo_belum_ditarik': 500000,
      },
      'limbah': {
        'total_diterima': 3000,
        'diterima_bulan_ini': 300,
      },
    };

    group('fromJson', () {
      test('should parse valid JSON correctly', () {
        final summary = AdminDashboardSummary.fromJson(testJson);
        expect(summary.perca, isNotNull);
        expect(summary.majun, isNotNull);
        expect(summary.expedisi, isNotNull);
        expect(summary.penjahit, isNotNull);
        expect(summary.limbah, isNotNull);
      });

      test('should handle empty nested objects', () {
        final summary = AdminDashboardSummary.fromJson({
          'perca': {},
          'majun': {},
          'expedisi': {},
          'penjahit': {},
          'limbah': {},
        });
        expect(summary.perca.stokGudang, 0);
        expect(summary.majun.totalDiterima, 0);
        expect(summary.expedisi.totalPengiriman, 0);
        expect(summary.penjahit.jumlahAktif, 0);
        expect(summary.limbah.totalDiterima, 0);
      });

      test('should handle completely missing nested objects', () {
        final summary = AdminDashboardSummary.fromJson({});
        expect(summary.perca, isNotNull);
        expect(summary.majun, isNotNull);
        expect(summary.expedisi, isNotNull);
        expect(summary.penjahit, isNotNull);
        expect(summary.limbah, isNotNull);
      });

      test('should populate all summary objects correctly', () {
        final summary = AdminDashboardSummary.fromJson(testJson);
        
        expect(summary.perca.stokGudang, 1000);
        expect(summary.majun.totalDiterima, 5000);
        expect(summary.expedisi.totalPengiriman, 50);
        expect(summary.penjahit.jumlahAktif, 25);
        expect(summary.limbah.totalDiterima, 3000);
      });
    });

    group('Constructor', () {
      test('should create AdminDashboardSummary with all summaries', () {
        final summary = AdminDashboardSummary.fromJson(testJson);
        final constructed = AdminDashboardSummary(
          perca: summary.perca,
          majun: summary.majun,
          expedisi: summary.expedisi,
          penjahit: summary.penjahit,
          limbah: summary.limbah,
        );
        
        expect(constructed.perca, summary.perca);
        expect(constructed.majun, summary.majun);
        expect(constructed.expedisi, summary.expedisi);
        expect(constructed.penjahit, summary.penjahit);
        expect(constructed.limbah, summary.limbah);
      });
    });
  });
}
