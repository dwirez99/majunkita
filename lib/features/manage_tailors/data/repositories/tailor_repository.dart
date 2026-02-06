import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tailor_model.dart';

/// Repository untuk mengelola data Tailor
/// Mengisolasi logika Supabase dari UI layer
class TailorRepository {
  final SupabaseClient _supabase;

  TailorRepository(this._supabase);

  // ===========================================================================
  // LOGGING HELPER
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
          .select('id, nama_lengkap, email, no_telp, alamat, spesialisasi, created_at, updated_at')
          .order('nama_lengkap', ascending: true)
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
          .select('id, nama_lengkap, email, no_telp, alamat, spesialisasi, created_at, updated_at')
          .ilike('nama_lengkap', '%$query%')
          .order('nama_lengkap', ascending: true);

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
          .select('id, nama_lengkap, email, no_telp, alamat, spesialisasi, created_at, updated_at')
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        _log('Tailor not found with ID: $id', level: 'WARN');
        return null;
      }

      final tailor = TailorModel.fromJson(response);
      _log('Successfully fetched tailor: ${tailor.namaLengkap}');
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
    required String namaLengkap,
    required String email,
    required String noTelp,
    String? alamat,
    String? spesialisasi,
  }) async {
    _log('Creating new tailor: $namaLengkap ($email)');
    try {
      final response = await _supabase
          .from('tailors')
          .insert({
            'nama_lengkap': namaLengkap,
            'email': email,
            'no_telp': noTelp,
            'alamat': alamat,
            'spesialisasi': spesialisasi,
          })
          .select('id, nama_lengkap, email, no_telp, alamat, spesialisasi, created_at, updated_at')
          .single();

      final tailor = TailorModel.fromJson(response);
      _log('Successfully created tailor: ${tailor.namaLengkap} (ID: ${tailor.id})');
      return tailor;
    } catch (e) {
      _log('Error creating tailor $namaLengkap: $e', level: 'ERROR');
      
      // Provide user-friendly error messages
      if (e.toString().contains('duplicate key') || 
          e.toString().contains('unique constraint')) {
        throw Exception('Email sudah terdaftar. Gunakan email lain.');
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
    required String namaLengkap,
    required String email,
    required String noTelp,
    String? alamat,
    String? spesialisasi,
  }) async {
    _log('Updating tailor: id=$id, nama=$namaLengkap');
    try {
      final response = await _supabase
          .from('tailors')
          .update({
            'nama_lengkap': namaLengkap,
            'email': email,
            'no_telp': noTelp,
            'alamat': alamat,
            'spesialisasi': spesialisasi,
          })
          .eq('id', id)
          .select('id, nama_lengkap, email, no_telp, alamat, spesialisasi, created_at, updated_at')
          .single();

      final tailor = TailorModel.fromJson(response);
      _log('Successfully updated tailor: ${tailor.namaLengkap} (ID: $id)');
      return tailor;
    } catch (e) {
      _log('Error updating tailor $id: $e', level: 'ERROR');
      
      // Provide user-friendly error messages
      if (e.toString().contains('duplicate key') || 
          e.toString().contains('unique constraint')) {
        throw Exception('Email sudah digunakan oleh penjahit lain.');
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
      await _supabase
          .from('tailors')
          .delete()
          .eq('id', id);

      _log('Successfully deleted tailor: id=$id');
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
          .select('id', const FetchOptions(count: CountOption.exact, head: true));

      final count = response.count ?? 0;
      _log('Total tailors: $count');
      return count;
    } catch (e) {
      _log('Error counting tailors: $e', level: 'ERROR');
      throw Exception('Gagal menghitung jumlah penjahit: $e');
    }
  }
}
