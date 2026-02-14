// ignore_for_file: avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/supabase_client_api.dart';
import '../../data/models/factory_model.dart';
import '../../data/repositories/factory_repository.dart';

// ===========================================================================
// REPOSITORY PROVIDER
// ===========================================================================

final factoryRepositoryProvider = Provider<FactoryRepository>((ref) {
  return FactoryRepository(
    ref.watch(supabaseClientProvider),
  );
});

// ===========================================================================
// SEARCH QUERY PROVIDER
// ===========================================================================

/// Notifier untuk search query
class FactorySearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
  void clear() => state = '';
}

final factorySearchQueryProvider =
    NotifierProvider<FactorySearchQueryNotifier, String>(
  FactorySearchQueryNotifier.new,
);

// ===========================================================================
// LIST PROVIDER (dengan auto-reload saat search query berubah)
// ===========================================================================

/// Provider untuk List Factory (dengan filter search otomatis)
final factoriesListProvider =
    FutureProvider.autoDispose<List<FactoryModel>>((ref) async {
  final repository = ref.watch(factoryRepositoryProvider);
  final query = ref.watch(factorySearchQueryProvider);

  // Jika query kosong, ambil semua. Jika ada, cari.
  if (query.isEmpty) {
    return repository.getAllFactories();
  } else {
    return repository.searchFactories(query);
  }
});

/// Provider untuk menghitung total factory
final factoryCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repository = ref.watch(factoryRepositoryProvider);
  return repository.getFactoryCount();
});

// ===========================================================================
// CRUD NOTIFIER
// ===========================================================================

/// Notifier untuk menangani Create/Update/Delete factory
class FactoryManagementNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Initial state void
  }

  void _log(String message, {String level = 'INFO'}) {
    final timestamp = DateTime.now().toString();
    // NOTE: Using print() to match existing codebase pattern.
    // Consider migrating to logger package for production.
    print('[$timestamp] [$level] FACTORY_MGMT_NOTIFIER: $message');
  }

  /// Create new factory
  Future<FactoryModel> createFactory({
    required String factoryName,
    required String address,
    required String noTelp,
  }) async {
    _log('Creating new factory: $factoryName');

    state = const AsyncValue.loading();

    try {
      final repository = ref.read(factoryRepositoryProvider);

      final factory = await repository.createFactory(
        factoryName: factoryName,
        address: address,
        noTelp: noTelp,
      );

      // Invalidate list provider to refresh the list
      ref.invalidate(factoriesListProvider);
      ref.invalidate(factoryCountProvider);

      _log('Successfully created factory: ${factory.factoryName}');
      state = const AsyncValue.data(null);

      return factory;
    } catch (e, st) {
      _log('Error creating factory $factoryName: $e', level: 'ERROR');
      state = AsyncValue.error(e, st);
      rethrow; // Lempar ulang error agar UI bisa menangkap
    }
  }

  /// Update existing factory
  Future<FactoryModel> updateFactory({
    required String id,
    required String factoryName,
    required String address,
    required String noTelp,
  }) async {
    _log('Updating factory: id=$id, name=$factoryName');

    state = const AsyncValue.loading();

    try {
      final repository = ref.read(factoryRepositoryProvider);

      final factory = await repository.updateFactory(
        id: id,
        factoryName: factoryName,
        address: address,
        noTelp: noTelp,
      );

      // Invalidate list provider to refresh the list
      ref.invalidate(factoriesListProvider);

      _log('Successfully updated factory: id=$id');
      state = const AsyncValue.data(null);

      return factory;
    } catch (e, st) {
      _log('Error updating factory $id: $e', level: 'ERROR');
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Delete factory
  Future<void> deleteFactory(String id) async {
    _log('Deleting factory: id=$id');

    state = const AsyncValue.loading();

    try {
      final repository = ref.read(factoryRepositoryProvider);

      await repository.deleteFactory(id);

      // Invalidate list provider to refresh the list
      ref.invalidate(factoriesListProvider);
      ref.invalidate(factoryCountProvider);

      _log('Successfully deleted factory: id=$id');
      state = const AsyncValue.data(null);
    } catch (e, st) {
      _log('Error deleting factory $id: $e', level: 'ERROR');
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

/// Provider tunggal untuk dipanggil di UI
final factoryManagementProvider =
    AsyncNotifierProvider<FactoryManagementNotifier, void>(
  FactoryManagementNotifier.new,
);
