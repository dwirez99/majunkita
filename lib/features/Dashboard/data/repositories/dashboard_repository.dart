// ignore_for_file: avoid_print

// lib/features/dashboard/data/repositories/dashboard_repository.dart
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_dashboard_models.dart';

class DashboardRepository {
  final SupabaseClient _supabase;
  DashboardRepository(this._supabase);

  Future<AdminDashboardSummary> getAdminDashboardSummary() async {
    try {
      // Panggil PostgreSQL Function menggunakan rpc (Remote Procedure Call)
      final data = await _supabase.rpc('get_admin_dashboard_summary');

      // Hasilnya adalah Map<String, dynamic>, siap diubah oleh model kita
      return AdminDashboardSummary.fromJson(data);
    } catch (e) {
      // Tangani error dengan baik
      print('Error fetching dashboard summary: $e');
      throw Exception('Gagal memuat data dashboard. Coba lagi nanti.');
    }
  }

  /// Ringkasan expedisi untuk driver yang sedang login.
  Future<Map<String, dynamic>> getDriverExpeditionSummary() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('User tidak ditemukan.');

    try {
      final rows = await _supabase
          .from('expeditions')
          .select('sack_number, total_weight, expedition_date')
          .eq('id_partner', uid);

      // Hitung total
      int totalPengiriman = rows.length;
      num totalKarung = 0;
      num totalBerat = 0;

      // Hitung bulan ini
      final now = DateTime.now();
      int pengirimanBulanIni = 0;
      num beratBulanIni = 0;

      for (final row in rows) {
        final sack = num.tryParse(row['sack_number']?.toString() ?? '0') ?? 0;
        final weight =
            num.tryParse(row['total_weight']?.toString() ?? '0') ?? 0;
        totalKarung += sack;
        totalBerat += weight;

        final dateStr = row['expedition_date']?.toString();
        if (dateStr != null) {
          final date = DateTime.tryParse(dateStr);
          if (date != null &&
              date.year == now.year &&
              date.month == now.month) {
            pengirimanBulanIni++;
            beratBulanIni += weight;
          }
        }
      }

      final _w = NumberFormat('#,##0.##', 'id_ID');

      return {
        'total_pengiriman': totalPengiriman,
        'total_karung': totalKarung,
        'total_berat': totalBerat,
        'fmt_total_berat': '${_w.format(totalBerat)} kg',
        'pengiriman_bulan_ini': pengirimanBulanIni,
        'berat_bulan_ini': beratBulanIni,
        'fmt_berat_bulan_ini': '${_w.format(beratBulanIni)} kg',
      };
    } catch (e) {
      print('Error fetching driver summary: $e');
      throw Exception('Gagal memuat ringkasan pengiriman.');
    }
  }
}