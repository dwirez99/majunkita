import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:majunkita/features/manage_tailors/data/models/tailor_model.dart';

class PercaTransactionsRepository {
  final SupabaseClient _supabase;

  PercaTransactionsRepository(this._supabase);

  // ============================================================
  // 1. MENGAMBIL DATA PENDUKUNG (Tailors)
  // ============================================================

  /// Mengambil daftar Tailor untuk dropdown
  Future<List<TailorModel>> getTailorList() async {
    try {
      final data = await _supabase
          .from('tailors')
          .select('id, name, address, no_telp, created_at, tailor_images');
      return data.map((item) => TailorModel.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil daftar Tailor: $e');
    }
  }

  // ============================================================
  // 2. SACK CODE - Ambil Ringkasan Stok Tersedia
  // ============================================================

  /// Ambil ringkasan stok tersedia per sack_code via RPC
  /// Return: [{sack_code, perca_type, total_sacks, total_weight}, ...]
  Future<List<Map<String, dynamic>>> getAvailableSackSummary() async {
    try {
      final response = await _supabase.rpc('get_available_sack_summary');
      // RPC returns JSONB array
      if (response is List) {
        return List<Map<String, dynamic>>.from(
          response.map((item) => Map<String, dynamic>.from(item)),
        );
      }
      return [];
    } catch (e) {
      throw Exception('Gagal mengambil ringkasan stok tersedia: $e');
    }
  }

  /// Ambil jumlah karung tersedia untuk sack_code tertentu
  Future<int> getAvailableSackCount(String sackCode) async {
    try {
      final data = await _supabase
          .from('percas_stock')
          .select('id')
          .eq('sack_code', sackCode)
          .eq('status', 'tersedia');
      return data.length;
    } catch (e) {
      throw Exception('Gagal mengambil jumlah stok untuk $sackCode: $e');
    }
  }

  // ============================================================
  // 3. CREATE - Proses Transaksi via RPC
  // ============================================================

  /// Proses transaksi perca menggunakan RPC process_transaction_by_sack_code
  /// Otomatis FIFO, update status stok, dan insert ke perca_transactions
  Future<Map<String, dynamic>> processTransactionBySackCode({
    required String idTailor,
    required String staffId,
    required String sackCode,
    required int sackCount,
    required DateTime dateEntry,
  }) async {
    try {
      final response = await _supabase.rpc(
        'process_transaction_by_sack_code',
        params: {
          'p_id_tailor': idTailor,
          'p_staff_id': staffId,
          'p_sack_code': sackCode,
          'p_sack_count': sackCount,
          'p_date_entry': dateEntry.toIso8601String().split('T').first,
        },
      );
      return Map<String, dynamic>.from(response);
    } catch (e) {
      throw Exception('Gagal memproses transaksi: $e');
    }
  }

  // ============================================================
  // 4. READ - Ambil Riwayat Transaksi Perca
  // ============================================================

  /// Ambil semua riwayat transaksi perca
  Future<List<Map<String, dynamic>>> getPercaTransactionHistory() async {
    try {
      final data = await _supabase
          .from('perca_transactions')
          .select(
            'id, id_stock_perca, id_tailors, date_entry, percas_type, weight, staff_id, created_at, tailors(name)',
          )
          .order('date_entry', ascending: false)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw Exception('Gagal mengambil riwayat transaksi perca: $e');
    }
  }

  /// Ambil riwayat transaksi perca berdasarkan ID Tailor tertentu
  Future<List<Map<String, dynamic>>> getTransactionsByTailor(
    String tailorId,
  ) async {
    try {
      final data = await _supabase
          .from('perca_transactions')
          .select(
            'id, id_stock_perca, id_tailors, date_entry, percas_type, weight, staff_id, created_at, tailors(name)',
          )
          .eq('id_tailors', tailorId)
          .order('date_entry', ascending: false)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw Exception('Gagal mengambil transaksi untuk tailor: $e');
    }
  }

  /// Ambil detail satu transaksi perca berdasarkan ID
  Future<Map<String, dynamic>> getPercaTransactionById(
    String transactionId,
  ) async {
    try {
      final data =
          await _supabase
              .from('perca_transactions')
              .select(
                'id, id_stock_perca, id_tailors, date_entry, percas_type, weight, staff_id, created_at, tailors(name)',
              )
              .eq('id', transactionId)
              .single();
      return Map<String, dynamic>.from(data);
    } catch (e) {
      throw Exception('Gagal mengambil detail transaksi perca: $e');
    }
  }

  // ============================================================
  // 5. UPDATE - Update Transaksi Perca
  // ============================================================

  /// Update data transaksi perca berdasarkan ID
  Future<void> updatePercaTransaction(
    String transactionId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      await _supabase
          .from('perca_transactions')
          .update(updateData)
          .eq('id', transactionId);
    } catch (e) {
      throw Exception('Gagal mengupdate transaksi perca: $e');
    }
  }

  // ============================================================
  // 6. DELETE - Hapus Transaksi Perca
  // ============================================================

  /// Hapus transaksi perca berdasarkan ID
  Future<void> deletePercaTransaction(String transactionId) async {
    try {
      await _supabase
          .from('perca_transactions')
          .delete()
          .eq('id', transactionId);
    } catch (e) {
      throw Exception('Gagal menghapus transaksi perca: $e');
    }
  }

  // ============================================================
  // 7. STATISTIK - Data Statistik Transaksi
  // ============================================================

  /// Ambil statistik bulanan transaksi perca (total berat per bulan)
  Future<Map<String, double>> getMonthlyTransactionStats() async {
    try {
      final data = await _supabase
          .from('perca_transactions')
          .select('date_entry, weight')
          .order('date_entry', ascending: true);

      Map<String, double> stats = {};

      for (var item in data) {
        if (item['date_entry'] != null && item['weight'] != null) {
          try {
            final date = DateTime.parse(item['date_entry'].toString());
            final monthKey =
                '${date.year}-${date.month.toString().padLeft(2, '0')}';
            final weight = double.tryParse(item['weight'].toString()) ?? 0.0;

            if (stats.containsKey(monthKey)) {
              stats[monthKey] = stats[monthKey]! + weight;
            } else {
              stats[monthKey] = weight;
            }
          } catch (e) {
            // Skip invalid date entries
          }
        }
      }

      return stats;
    } catch (e) {
      throw Exception('Gagal mengambil statistik transaksi: $e');
    }
  }

  /// Ambil total berat transaksi per tailor
  Future<Map<String, double>> getTotalWeightPerTailor() async {
    try {
      final data = await _supabase
          .from('perca_transactions')
          .select('id_tailors, weight, tailors(name)');

      Map<String, double> tailorWeight = {};

      for (var item in data) {
        final tailorName = item['tailors']?['name']?.toString() ?? 'Unknown';
        final weight =
            double.tryParse(item['weight']?.toString() ?? '0') ?? 0.0;

        if (tailorWeight.containsKey(tailorName)) {
          tailorWeight[tailorName] = tailorWeight[tailorName]! + weight;
        } else {
          tailorWeight[tailorName] = weight;
        }
      }

      return tailorWeight;
    } catch (e) {
      throw Exception('Gagal mengambil total berat per tailor: $e');
    }
  }
}
