// ignore_for_file: avoid_print

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service untuk mengelola upload dan delete file ke Supabase Storage
class StorageService {
  final SupabaseClient _supabase;

  StorageService(this._supabase);

  // ===========================================================================
  // LOGGING HELPER
  // ===========================================================================

  void _log(String message, {String level = 'INFO'}) {
    final timestamp = DateTime.now().toString();
    print('[$timestamp] [$level] STORAGE_SERVICE: $message');
  }

  // ===========================================================================
  // UPLOAD OPERATIONS
  // ===========================================================================

  /// Upload gambar penjahit ke Supabase Storage
  ///
  /// Returns: Public URL dari file yang berhasil diupload
  Future<String> uploadTailorImage({
    required File imageFile,
    required String tailorId,
  }) async {
    _log('Uploading tailor image for ID: $tailorId');

    try {
      // Generate unique filename
      final fileName =
          'tailor_${tailorId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      _log(
        'Uploading to bucket: majunkita, folder: tailor_images, file: $fileName',
      );

      // Upload ke bucket 'majunkita' folder 'tailor_images'
      final response = await _supabase.storage
          .from('majunkita')
          .upload('tailor_images/$fileName', imageFile);

      if (response.isEmpty) {
        throw Exception("Failed to upload image to Supabase Storage");
      }

      // Get public URL
      final publicUrl = _supabase.storage
          .from('majunkita')
          .getPublicUrl('tailor_images/$fileName');

      _log('Successfully uploaded image: $publicUrl');
      return publicUrl;
    } catch (e) {
      _log('Error uploading tailor image: $e', level: 'ERROR');
      throw Exception('Gagal upload gambar: $e');
    }
  }

  // ===========================================================================
  // DELETE OPERATIONS
  // ===========================================================================

  /// Delete gambar penjahit dari Supabase Storage
  Future<void> deleteTailorImage(String imageUrl) async {
    _log('Deleting tailor image: $imageUrl');

    try {
      // Extract file path from public URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // URL format: https://xxx.supabase.co/storage/v1/object/public/majunkita/tailor_images/file.jpg
      // We need to find 'majunkita' and get everything after it
      final bucketIndex = pathSegments.indexOf('majunkita');
      if (bucketIndex == -1) {
        throw Exception('Invalid image URL format');
      }

      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

      _log('Deleting from bucket: majunkita, path: $filePath');

      await _supabase.storage.from('majunkita').remove([filePath]);

      _log('Successfully deleted image: $filePath');
    } catch (e) {
      _log('Error deleting tailor image: $e', level: 'ERROR');
      // Don't throw error on delete failure - it's not critical
      _log('Continuing despite delete error', level: 'WARN');
    }
  }

  /// Delete semua gambar tailor berdasarkan ID (dengan pattern filename)
  Future<void> deleteTailorImageFolder(String tailorId) async {
    _log('Deleting all images for tailor: $tailorId');

    try {
      // List all files in the tailor_images folder
      final files = await _supabase.storage
          .from('majunkita')
          .list(path: 'tailor_images');

      if (files.isEmpty) {
        _log('No images found in tailor_images folder');
        return;
      }

      // Filter files that match the tailor ID pattern (tailor_{tailorId}_*.jpg)
      final tailorFiles =
          files
              .where((file) => file.name.startsWith('tailor_${tailorId}_'))
              .toList();

      if (tailorFiles.isEmpty) {
        _log('No images found for tailor: $tailorId');
        return;
      }

      // Create list of file paths to delete
      final filePaths =
          tailorFiles.map((file) => 'tailor_images/${file.name}').toList();

      _log('Deleting ${filePaths.length} file(s) for tailor: $tailorId');

      // Delete all files
      await _supabase.storage.from('majunkita').remove(filePaths);

      _log('Successfully deleted ${filePaths.length} image(s)');
    } catch (e) {
      _log('Error deleting tailor image folder: $e', level: 'ERROR');
      // Don't throw error on delete failure - it's not critical
      _log('Continuing despite delete error', level: 'WARN');
    }
  }
}
