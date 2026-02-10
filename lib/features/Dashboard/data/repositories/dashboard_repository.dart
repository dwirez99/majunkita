// ignore_for_file: avoid_print

// lib/features/dashboard/data/repositories/dashboard_repository.dart
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
}