// ignore_for_file: avoid_print

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/image_compressor.dart';
import '../models/expedition_model.dart';

/// Repository untuk mengelola data Expedisi
/// Mengisolasi logika Supabase dari UI layer
class ExpeditionRepository {
  final SupabaseClient _supabase;

  ExpeditionRepository(this._supabase);

  // ===========================================================================
  // LOGGING HELPER
  // ===========================================================================

  void _log(String message, {String level = 'INFO'}) {
    final timestamp = DateTime.now().toString();
    print('[$timestamp] [$level] EXPEDITION_REPOSITORY: $message');
  }

  // ===========================================================================
  // READ OPERATIONS
  // ===========================================================================

  /// Mengambil semua data expedisi, di-join dengan tabel profiles untuk nama partner
  Future<List<ExpeditionModel>> getExpeditions() async {
    _log('Fetching all expeditions...');
    try {
      // Lakukan query dengan JOIN ke tabel profiles untuk mendapatkan nama driver
      // dan JOIN ke expedition_partners untuk mendapatkan nama mitra expedisi
      final response = await _supabase
          .from('expeditions')
          .select(
            'id, id_partner, id_expedition_partner, expedition_date, destination, '
            'sack_number, total_weight, proof_of_delivery, '
            'profiles(name), expedition_partners(name)',
          )
          .order('expedition_date', ascending: false);

      // Konversi setiap item JSON ke ExpeditionModel
      final expeditions = (response as List)
          .map((json) => ExpeditionModel.fromJson(json))
          .toList();

      _log('Successfully fetched ${expeditions.length} expeditions');
      return expeditions;
    } catch (e) {
      _log('Error fetching expeditions: $e', level: 'ERROR');
      throw Exception('Gagal mengambil data expedisi: $e');
    }
  }

  // ===========================================================================
  // CREATE OPERATION
  // ===========================================================================

  /// Membuat data expedisi baru dengan upload bukti pengiriman ke Supabase Storage
  ///
  /// [data] - Data expedisi yang akan disimpan
  /// [imageFile] - File gambar bukti pengiriman yang akan diupload
  Future<ExpeditionModel> createExpedition(
    ExpeditionModel data,
    File imageFile,
  ) async {
    _log('Creating new expedition to ${data.destination}...');
    try {
      // Compress image before uploading
      final compressedFile = await ImageCompressor.compressImage(imageFile);

      // 1. Generate nama file unik untuk menghindari konflik nama
      final fileName =
          'proof_${DateTime.now().millisecondsSinceEpoch}.jpg';
      _log('Uploading proof of delivery: $fileName');

      // 2. Upload gambar ke bucket 'proof_of_deliveries' di Supabase Storage
      final uploadResponse = await _supabase.storage
          .from('proof_of_deliveries')
          .upload(fileName, compressedFile);

      if (uploadResponse.isEmpty) {
        throw Exception('Gagal mengupload bukti pengiriman ke storage');
      }

      // 3. Dapatkan URL publik dari file yang baru diupload
      final publicUrl = _supabase.storage
          .from('proof_of_deliveries')
          .getPublicUrl(fileName);

      _log('Successfully uploaded proof of delivery: $publicUrl');

      // 4. Update data dengan URL bukti pengiriman yang baru
      final expeditionWithProof = data.copyWith(proofOfDelivery: publicUrl);

      // 5. Insert data expedisi ke tabel 'expeditions' di database
      final response = await _supabase
          .from('expeditions')
          .insert(expeditionWithProof.toJson()..remove('id'))
          .select(
            'id, id_partner, id_expedition_partner, expedition_date, destination, '
            'sack_number, total_weight, proof_of_delivery, '
            'profiles(name), expedition_partners(name)',
          )
          .single();

      final expedition = ExpeditionModel.fromJson(response);
      _log('Successfully created expedition: ${expedition.id}');
      return expedition;
    } catch (e) {
      _log('Error creating expedition: $e', level: 'ERROR');
      throw Exception('Gagal membuat data expedisi: $e');
    }
  }

  // ===========================================================================
  // DELETE OPERATION
  // ===========================================================================

  /// Menghapus data expedisi dari database DAN file dari storage
  ///
  /// [id] - UUID dari expedisi yang akan dihapus
  /// [imageUrl] - URL publik dari bukti pengiriman untuk dihapus dari storage
  Future<void> deleteExpedition(String id, String imageUrl) async {
    _log('Deleting expedition: id=$id');
    try {
      // 1. Hapus record dari database terlebih dahulu
      await _supabase.from('expeditions').delete().eq('id', id);
      _log('Successfully deleted expedition from database: id=$id');

      // 2. Ekstrak path file dari URL publik untuk menghapus dari storage
      if (imageUrl.isNotEmpty) {
        try {
          final uri = Uri.parse(imageUrl);
          final pathSegments = uri.pathSegments;

          // Format URL: https://xxx.supabase.co/storage/v1/object/public/proof_of_deliveries/file.jpg
          // Kita perlu mencari 'proof_of_deliveries' dan mengambil path setelahnya
          final bucketIndex =
              pathSegments.indexOf('proof_of_deliveries');
          if (bucketIndex != -1) {
            final filePath =
                pathSegments.sublist(bucketIndex + 1).join('/');
            _log('Deleting proof of delivery from storage: $filePath');

            // Hapus file dari bucket storage
            await _supabase.storage
                .from('proof_of_deliveries')
                .remove([filePath]);
            _log('Successfully deleted proof of delivery from storage');
          }
        } catch (e) {
          // Jangan lempar error jika hapus file gagal - data sudah terhapus dari DB
          _log(
            'Warning: Failed to delete proof of delivery from storage: $e',
            level: 'WARN',
          );
        }
      }

      _log('Successfully completed delete operation for expedition: id=$id');
    } catch (e) {
      _log('Error deleting expedition $id: $e', level: 'ERROR');
      throw Exception('Gagal menghapus data expedisi: $e');
    }
  }

  // ===========================================================================
  // STOCK CHECK — RPC
  // ===========================================================================

  /// Memanggil RPC get_majun_available_stock() untuk mendapatkan stok gudang saat ini.
  /// Hasilnya adalah: SUM(majun_transactions.weight_majun) - SUM(expeditions.total_weight)
  Future<double> getAvailableStock() async {
    _log('Fetching available majun stock via RPC...');
    try {
      final result = await _supabase.rpc('get_majun_available_stock');
      final stock = double.tryParse(result?.toString() ?? '0') ?? 0.0;
      _log('Available stock = $stock kg');
      return stock;
    } catch (e) {
      _log('Error fetching available stock: $e', level: 'ERROR');
      throw Exception('Gagal mengambil stok tersedia: $e');
    }
  }

  // ===========================================================================
  // APP SETTINGS — WEIGHT PER SACK
  // ===========================================================================

  /// Ambil berat standar per karung dari app_settings
  Future<int> getWeightPerSack() async {
    _log('Fetching weight_per_sack from app_settings...');
    try {
      final data = await _supabase
          .from('app_settings')
          .select('value')
          .eq('key', 'weight_per_sack')
          .single();
      final parsed = int.tryParse(data['value']?.toString() ?? '50') ?? 50;
      _log('weight_per_sack = $parsed kg');
      return parsed;
    } catch (e) {
      _log('Error fetching weight_per_sack: $e', level: 'ERROR');
      throw Exception('Gagal mengambil berat per karung: $e');
    }
  }

  /// Update berat standar per karung di app_settings
  Future<void> updateWeightPerSack(int newWeight) async {
    _log('Updating weight_per_sack to $newWeight kg...');
    try {
      final staffId = _supabase.auth.currentUser?.id;
      await _supabase
          .from('app_settings')
          .update({
            'value': newWeight.toString(),
            'updated_at': DateTime.now().toIso8601String(),
            'updated_by': staffId,
          })
          .eq('key', 'weight_per_sack');
      _log('weight_per_sack updated successfully');
    } catch (e) {
      _log('Error updating weight_per_sack: $e', level: 'ERROR');
      throw Exception('Gagal mengubah berat per karung: $e');
    }
  }
}
