import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../manage_tailors/data/models/tailor_model.dart';
import '../model/majun_transactions_model.dart';
import '../../../../core/utils/image_compressor.dart';

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
          .select(
            'id, name, address, no_telp, created_at, tailor_images, total_stock, balance',
          );
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
      // Compress image before uploading
      final compressedFile = await ImageCompressor.compressImage(imageFile);

      final fileName =
          '${folder}_${tailorId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final response = await _supabase.storage
          .from('majunkita')
          .upload('$folder/$fileName', compressedFile);

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

  /// Ambil riwayat setor majun (paginated)
  Future<List<MajunTransactionsModel>> getMajunHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase.rpc(
        'rpc_get_majun_history',
        params: {'p_limit': limit, 'p_offset': offset},
      );
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

  /// Ambil riwayat setor limbah (paginated)
  Future<List<LimbahTransactionsModel>> getLimbahHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase.rpc(
        'rpc_get_limbah_history',
        params: {'p_limit': limit, 'p_offset': offset},
      );
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

  /// Ambil statistik bulanan setor majun (server-side aggregation)
  Future<Map<String, double>> getMonthlyMajunStats() async {
    try {
      final response = await _supabase.rpc('rpc_get_monthly_majun_stats');

      Map<String, double> stats = {};
      if (response is List) {
        for (var item in response) {
          final monthKey = item['month_key']?.toString() ?? '';
          final totalWeight =
              double.tryParse(item['total_weight']?.toString() ?? '0') ?? 0.0;
          if (monthKey.isNotEmpty) {
            stats[monthKey] = totalWeight;
          }
        }
      }
      return stats;
    } catch (e) {
      throw Exception('Gagal mengambil statistik setor majun: $e');
    }
  }
}
