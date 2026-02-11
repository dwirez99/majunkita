// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/factory_models.dart';

/// Repository untuk mengelola data Factory
/// Mengisolasi logika Supabase dari UI layer
class FactoryRepository {
  final SupabaseClient _supabase;

  FactoryRepository(this._supabase);

  // ===========================================================================
  // LOGGING HELPER
  // NOTE: Using print() to match existing codebase pattern.
  // Consider migrating to a proper logging framework (e.g., logger package)
  // for better log management in the future.
  // ===========================================================================

  void _log(String message, {String level = 'INFO'}) {
    final timestamp = DateTime.now().toString();
    print('[$timestamp] [$level] FACTORY_REPOSITORY: $message');
  }

  // ===========================================================================
  // READ OPERATIONS
  // ===========================================================================

  /// Mengambil semua data factory dengan pagination
  /// Menggunakan specific column selection untuk efisiensi
  Future<List<FactoryModel>> getAllFactories({
    int page = 1,
    int limit = 50,
  }) async {
    _log('Fetching factories (page: $page, limit: $limit)...');
    try {
      final offset = (page - 1) * limit;

      // Gunakan .select() dengan kolom spesifik, BUKAN .select(*)
      final response = await _supabase
          .from('factories')
          .select('id, factory_name, address, no_telp')
          .order('factory_name', ascending: true)
          .range(offset, offset + limit - 1);

      final factories = (response as List)
          .map((json) => FactoryModel.fromJson(json))
          .toList();

      _log('Successfully fetched ${factories.length} factories');
      return factories;
    } catch (e) {
      _log('Error fetching factories: $e', level: 'ERROR');
      throw Exception('Gagal mengambil data pabrik: $e');
    }
  }

  /// Mencari factory berdasarkan nama
  Future<List<FactoryModel>> searchFactories(String query) async {
    _log('Searching factories with query: "$query"');
    try {
      if (query.isEmpty) {
        return getAllFactories();
      }

      final response = await _supabase
          .from('factories')
          .select('id, factory_name, address, no_telp')
          .ilike('factory_name', '%$query%')
          .order('factory_name', ascending: true);

      final factories = (response as List)
          .map((json) => FactoryModel.fromJson(json))
          .toList();

      _log('Search found ${factories.length} factory(ies) matching "$query"');
      return factories;
    } catch (e) {
      _log('Error searching factories: $e', level: 'ERROR');
      throw Exception('Gagal mencari data pabrik: $e');
    }
  }

  /// Mengambil detail factory berdasarkan ID
  Future<FactoryModel?> getFactoryById(String id) async {
    _log('Fetching factory by ID: $id');
    try {
      final response = await _supabase
          .from('factories')
          .select('id, factory_name, address, no_telp')
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        _log('Factory not found with ID: $id', level: 'WARN');
        return null;
      }

      final factory = FactoryModel.fromJson(response);
      _log('Successfully fetched factory: ${factory.factoryName}');
      return factory;
    } catch (e) {
      _log('Error fetching factory by ID $id: $e', level: 'ERROR');
      throw Exception('Gagal mengambil detail pabrik: $e');
    }
  }

  // ===========================================================================
  // CREATE OPERATION
  // ===========================================================================

  /// Membuat data factory baru
  Future<FactoryModel> createFactory({
    required String factoryName,
    required String address,
    required String noTelp,
  }) async {
    _log('Creating new factory: $factoryName');
    try {
      final response = await _supabase
          .from('factories')
          .insert({
            'factory_name': factoryName,
            'address': address,
            'no_telp': noTelp,
          })
          .select('id, factory_name, address, no_telp')
          .single();

      final factory = FactoryModel.fromJson(response);
      _log('Successfully created factory: ${factory.factoryName} (ID: ${factory.id})');
      return factory;
    } catch (e) {
      _log('Error creating factory $factoryName: $e', level: 'ERROR');

      // Provide user-friendly error messages
      if (e.toString().contains('duplicate key') ||
          e.toString().contains('unique constraint')) {
        throw Exception('Data pabrik sudah terdaftar. Gunakan data yang berbeda.');
      }

      throw Exception('Gagal membuat data pabrik: $e');
    }
  }

  // ===========================================================================
  // UPDATE OPERATION
  // ===========================================================================

  /// Mengupdate data factory
  Future<FactoryModel> updateFactory({
    required String id,
    required String factoryName,
    required String address,
    required String noTelp,
  }) async {
    _log('Updating factory: id=$id, name=$factoryName');
    try {
      final response = await _supabase
          .from('factories')
          .update({
            'factory_name': factoryName,
            'address': address,
            'no_telp': noTelp,
          })
          .eq('id', id)
          .select('id, factory_name, address, no_telp')
          .single();

      final factory = FactoryModel.fromJson(response);
      _log('Successfully updated factory: ${factory.factoryName} (ID: $id)');
      return factory;
    } catch (e) {
      _log('Error updating factory $id: $e', level: 'ERROR');

      // Provide user-friendly error messages
      if (e.toString().contains('duplicate key') ||
          e.toString().contains('unique constraint')) {
        throw Exception('Data sudah digunakan oleh pabrik lain.');
      }

      throw Exception('Gagal mengupdate data pabrik: $e');
    }
  }

  // ===========================================================================
  // DELETE OPERATION
  // ===========================================================================

  /// Menghapus data factory dengan pengecekan data integrity
  Future<void> deleteFactory(String id) async {
    _log('Deleting factory: id=$id');
    try {
      // Check if factory is used in percas_stock
      final usageCheck = await _supabase
          .from('percas_stock')
          .select('id', count: CountOption.exact)
          .eq('id_factory', id)
          .limit(1);

      if (usageCheck.count > 0) {
        _log('Cannot delete factory $id: still referenced in percas_stock', level: 'WARN');
        throw Exception(
          'Tidak dapat menghapus pabrik ini karena masih memiliki data stok perca terkait. '
          'Hapus terlebih dahulu semua data stok perca dari pabrik ini.'
        );
      }

      // If no usage, proceed with deletion
      await _supabase.from('factories').delete().eq('id', id);

      _log('Successfully deleted factory: id=$id');
    } catch (e) {
      // Re-throw if it's already our custom exception
      if (e.toString().contains('Tidak dapat menghapus')) {
        rethrow;
      }
      
      _log('Error deleting factory $id: $e', level: 'ERROR');
      throw Exception('Gagal menghapus data pabrik: $e');
    }
  }

  // ===========================================================================
  // UTILITY
  // ===========================================================================

  /// Menghitung total factory
  Future<int> getFactoryCount() async {
    _log('Counting total factories...');
    try {
      final response = await _supabase
          .from('factories')
          .select('id')
          .count(CountOption.exact);

      final count = response.count;
      _log('Total factories: $count');
      return count;
    } catch (e) {
      _log('Error counting factories: $e', level: 'ERROR');
      throw Exception('Gagal menghitung jumlah pabrik: $e');
    }
  }
}
