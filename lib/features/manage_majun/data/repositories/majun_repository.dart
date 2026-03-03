import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../manage_tailors/data/models/tailor_model.dart';
import '../model/majun_transactions_model.dart';

class MajunRepository {
  final SupabaseClient _supabase;

  MajunRepository(this._supabase);

  // ============================================================
  // PENDUKUNG
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

  /// Ambil harga standar majun per kg dari app_settings
  Future<double> getMajunPricePerKg() async {
    try {
      final data =
          await _supabase
              .from('app_settings')
              .select('value')
              .eq('key', 'majun_price_per_kg')
              .single();
      return double.tryParse(data['value']?.toString() ?? '0') ?? 0.0;
    } catch (e) {
      throw Exception('Gagal mengambil harga per kg: $e');
    }
  }

  /// Update harga standar majun per kg di app_settings
  Future<void> updateMajunPricePerKg(double newPrice) async {
    try {
      final staffId = _supabase.auth.currentUser?.id;

      await _supabase
          .from('app_settings')
          .update({
            'value': newPrice.toStringAsFixed(0),
            'updated_at': DateTime.now().toIso8601String(),
            'updated_by': staffId,
          })
          .eq('key', 'majun_price_per_kg');
    } catch (e) {
      throw Exception('Gagal mengubah harga per kg: $e');
    }
  }

  // ============================================================
  // UPLOAD FOTO BUKTI
  // ============================================================

  /// Upload foto bukti ke Supabase Storage, returns public URL
  Future<String> uploadDeliveryProof({
    required File imageFile,
    required String tailorId,
    String folder = 'majun_photos',
  }) async {
    try {
      final fileName =
          '${folder}_${tailorId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final response = await _supabase.storage
          .from('majunkita')
          .upload('$folder/$fileName', imageFile);

      if (response.isEmpty) {
        throw Exception('Gagal upload foto ke Supabase Storage');
      }

      return _supabase.storage
          .from('majunkita')
          .getPublicUrl('$folder/$fileName');
    } catch (e) {
      throw Exception('Gagal upload foto bukti: $e');
    }
  }

  // ============================================================
  // SETOR MAJUN (Direct INSERT — trigger auto earned_wage & update tailors)
  // ============================================================

  /// Insert setor majun. Trigger di DB akan:
  /// - BEFORE INSERT: Auto-hitung earned_wage = weight_majun × price_per_kg
  /// - AFTER INSERT: UPDATE tailors SET total_stock -= weight_majun, balance += earned_wage
  Future<SetorMajunResult> setorMajun({
    required String tailorId,
    required double weightMajun,
    required String deliveryProof,
    required String staffId,
  }) async {
    try {
      final result =
          await _supabase
              .from('majun_transactions')
              .insert({
                'id_tailor': tailorId,
                'weight_majun': weightMajun,
                'staff_id': staffId,
                'delivery_proof': deliveryProof,
                'date_entry': DateTime.now().toIso8601String().split('T').first,
              })
              .select()
              .single();

      return SetorMajunResult.fromJson(result);
    } catch (e) {
      throw Exception('Gagal setor majun: $e');
    }
  }

  // ============================================================
  // SETOR LIMBAH (Direct INSERT — trigger auto update tailors)
  // ============================================================

  /// Insert setor limbah. Trigger di DB akan:
  /// - AFTER INSERT: UPDATE tailors SET total_stock -= weight_limbah (tanpa upah)
  Future<LimbahTransactionsModel> setorLimbah({
    required String tailorId,
    required double weightLimbah,
    required String staffId,
    String? deliveryProof,
  }) async {
    try {
      final result =
          await _supabase
              .from('limbah_transactions')
              .insert({
                'id_tailor': tailorId,
                'weight_limbah': weightLimbah,
                'staff_id': staffId,
                'delivery_proof': deliveryProof,
                'date_entry': DateTime.now().toIso8601String().split('T').first,
              })
              .select()
              .single();

      return LimbahTransactionsModel.fromJson(result);
    } catch (e) {
      throw Exception('Gagal setor limbah: $e');
    }
  }

  // ============================================================
  // RIWAYAT (via RPC untuk join nama penjahit)
  // ============================================================

  /// Ambil riwayat setor majun
  Future<List<MajunTransactionsModel>> getMajunHistory() async {
    try {
      final response = await _supabase.rpc('rpc_get_majun_history');
      if (response is List) {
        return response
            .map(
              (item) => MajunTransactionsModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Gagal mengambil riwayat setor majun: $e');
    }
  }

  /// Ambil riwayat setor limbah
  Future<List<LimbahTransactionsModel>> getLimbahHistory() async {
    try {
      final response = await _supabase.rpc('rpc_get_limbah_history');
      if (response is List) {
        return response
            .map(
              (item) => LimbahTransactionsModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Gagal mengambil riwayat setor limbah: $e');
    }
  }

  // ============================================================
  // STATISTIK
  // ============================================================

  /// Ambil statistik bulanan setor majun
  Future<Map<String, double>> getMonthlyMajunStats() async {
    try {
      final data = await _supabase
          .from('majun_transactions')
          .select('date_entry, weight_majun')
          .order('date_entry', ascending: true);

      Map<String, double> stats = {};
      for (var item in data) {
        if (item['date_entry'] != null && item['weight_majun'] != null) {
          try {
            final date = DateTime.parse(item['date_entry'].toString());
            final monthKey =
                '${date.year}-${date.month.toString().padLeft(2, '0')}';
            final weight =
                double.tryParse(item['weight_majun'].toString()) ?? 0.0;
            stats[monthKey] = (stats[monthKey] ?? 0) + weight;
          } catch (_) {}
        }
      }
      return stats;
    } catch (e) {
      throw Exception('Gagal mengambil statistik setor majun: $e');
    }
  }
}
