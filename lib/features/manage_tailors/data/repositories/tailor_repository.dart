// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tailor_model.dart';
import '../../../../core/services/storage_service.dart';

/// Repository untuk mengelola data Tailor
/// Mengisolasi logika Supabase dari UI layer
class TailorRepository {
  final SupabaseClient _supabase;
  final StorageService _storageService;

  TailorRepository(this._supabase, this._storageService);

  // ===========================================================================
  // LOGGING HELPER
  // NOTE: Using print() to match existing codebase pattern.
  // Consider migrating to a proper logging framework (e.g., logger package)
  // for better log management in the future.
  // ===========================================================================

  void _log(String message, {String level = 'INFO'}) {
    final timestamp = DateTime.now().toString();
    print('[$timestamp] [$level] TAILOR_REPOSITORY: $message');
  }

  // ===========================================================================
  // READ OPERATIONS
  // ===========================================================================

  /// Mengambil semua data tailor dengan pagination
  /// Menggunakan specific column selection untuk efisiensi
  Future<List<TailorModel>> getAllTailors({
    int page = 1,
    int limit = 20,
  }) async {
    _log('Fetching tailors (page: $page, limit: $limit)...');
    try {
      final offset = (page - 1) * limit;

      // Gunakan .select() dengan kolom spesifik, BUKAN .select(*)
      final response = await _supabase
          .from('tailors')
          .select('id, name, no_telp, address, tailor_images, created_at')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final tailors = (response as List)
          .map((json) => TailorModel.fromJson(json))
          .toList();

      _log('Successfully fetched ${tailors.length} tailors');
      return tailors;
    } catch (e) {
      _log('Error fetching tailors: $e', level: 'ERROR');
      throw Exception('Gagal mengambil data penjahit: $e');
    }
  }

  /// Mencari tailor berdasarkan nama
  Future<List<TailorModel>> searchTailors(String query) async {
    _log('Searching tailors with query: "$query"');
    try {
      if (query.isEmpty) {
        return getAllTailors();
      }

      final response = await _supabase
          .from('tailors')
          .select('id, name, no_telp, address, tailor_images, created_at')
          .ilike('name', '%$query%')
          .order('name', ascending: true);

      final tailors = (response as List)
          .map((json) => TailorModel.fromJson(json))
          .toList();

      _log('Search found ${tailors.length} tailor(s) matching "$query"');
      return tailors;
    } catch (e) {
      _log('Error searching tailors: $e', level: 'ERROR');
      throw Exception('Gagal mencari data penjahit: $e');
    }
  }

  /// Mengambil detail tailor berdasarkan ID
  Future<TailorModel?> getTailorById(String id) async {
    _log('Fetching tailor by ID: $id');
    try {
      final response = await _supabase
          .from('tailors')
          .select('id, name, no_telp, address, tailor_images, created_at')
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        _log('Tailor not found with ID: $id', level: 'WARN');
        return null;
      }

      final tailor = TailorModel.fromJson(response);
      _log('Successfully fetched tailor: ${tailor.name}');
      return tailor;
    } catch (e) {
      _log('Error fetching tailor by ID $id: $e', level: 'ERROR');
      throw Exception('Gagal mengambil detail penjahit: $e');
    }
  }

  // ===========================================================================
  // CREATE OPERATION
  // ===========================================================================

  /// Membuat data tailor baru
  Future<TailorModel> createTailor({
    required String name,
    required String noTelp,
    required String address,
    String? tailorImages,
  }) async {
    _log('Creating new tailor: $name');
    try {
      final response = await _supabase
          .from('tailors')
          .insert({
            'name': name,
            'no_telp': noTelp,
            'address': address,
            'tailor_images': tailorImages,
          })
          .select('id, name, no_telp, address, tailor_images, created_at')
          .single();

      final tailor = TailorModel.fromJson(response);
      _log('Successfully created tailor: ${tailor.name} (ID: ${tailor.id})');
      return tailor;
    } catch (e) {
      _log('Error creating tailor $name: $e', level: 'ERROR');

      // Provide user-friendly error messages
      if (e.toString().contains('duplicate key') ||
          e.toString().contains('unique constraint')) {
        throw Exception('Data penjahit sudah terdaftar. Gunakan data yang berbeda.');
      }

      throw Exception('Gagal membuat data penjahit: $e');
    }
  }

  // ===========================================================================
  // UPDATE OPERATION
  // ===========================================================================

  /// Mengupdate data tailor
  Future<TailorModel> updateTailor({
    required String id,
    required String name,
    required String noTelp,
    required String address,
    String? tailorImages,
    String? oldImageUrl, // Add parameter to track old image
  }) async {
    _log('Updating tailor: id=$id, nama=$name');
    try {
      // If there's a new image and an old image exists, delete the old one
      if (tailorImages != null &&
          tailorImages.isNotEmpty &&
          oldImageUrl != null &&
          oldImageUrl.isNotEmpty &&
          tailorImages != oldImageUrl) {
        _log('Deleting old image before update: $oldImageUrl');
        try {
          await _storageService.deleteTailorImage(oldImageUrl);
          _log('Successfully deleted old image');
        } catch (e) {
          _log('Warning: Failed to delete old image: $e', level: 'WARN');
          // Continue with update even if image deletion fails
        }
      }

      final response = await _supabase
          .from('tailors')
          .update({
            'name': name,
            'no_telp': noTelp,
            'address': address,
            'tailor_images': tailorImages,
          })
          .eq('id', id)
          .select('id, name, no_telp, address, tailor_images, created_at')
          .single();

      final tailor = TailorModel.fromJson(response);
      _log('Successfully updated tailor: ${tailor.name} (ID: $id)');
      return tailor;
    } catch (e) {
      _log('Error updating tailor $id: $e', level: 'ERROR');

      // Provide user-friendly error messages
      if (e.toString().contains('duplicate key') ||
          e.toString().contains('unique constraint')) {
        throw Exception('Data sudah digunakan oleh penjahit lain.');
      }

      throw Exception('Gagal mengupdate data penjahit: $e');
    }
  }

  // ===========================================================================
  // DELETE OPERATION
  // ===========================================================================

  /// Menghapus data tailor
  Future<void> deleteTailor(String id) async {
    _log('Deleting tailor: id=$id');
    try {
      // First, get the tailor data to retrieve the image URL
      final tailor = await getTailorById(id);

      // Delete the tailor from database
      await _supabase.from('tailors').delete().eq('id', id);

      _log('Successfully deleted tailor from database: id=$id');

      // Then delete associated images from storage
      if (tailor != null) {
        if (tailor.tailorImages != null && tailor.tailorImages!.isNotEmpty) {
          _log('Deleting tailor image: ${tailor.tailorImages}');
          try {
            await _storageService.deleteTailorImage(tailor.tailorImages!);
            _log('Successfully deleted tailor image');
          } catch (e) {
            _log('Warning: Failed to delete tailor image: $e', level: 'WARN');
            // Don't throw error - deletion was successful, just image cleanup failed
          }
        }

        // Also try to delete any orphaned images with this tailor ID
        try {
          await _storageService.deleteTailorImageFolder(id);
        } catch (e) {
          _log('Warning: Failed to delete tailor image folder: $e', level: 'WARN');
        }
      }

      _log('Successfully completed delete operation for tailor: id=$id');
    } catch (e) {
      _log('Error deleting tailor $id: $e', level: 'ERROR');
      throw Exception('Gagal menghapus data penjahit: $e');
    }
  }

  // ===========================================================================
  // UTILITY
  // ===========================================================================

  /// Menghitung total tailor
  Future<int> getTailorCount() async {
    _log('Counting total tailors...');
    try {
      final response = await _supabase
          .from('tailors')
          .select('id')
          .count(CountOption.exact);

      final count = response.count;
      _log('Total tailors: $count');
      return count;
    } catch (e) {
      _log('Error counting tailors: $e', level: 'ERROR');
      throw Exception('Gagal menghitung jumlah penjahit: $e');
    }
  }
}
