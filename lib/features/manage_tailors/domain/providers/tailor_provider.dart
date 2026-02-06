import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/supabase_client_api.dart';
import '../../data/models/tailor_model.dart';
import '../../data/repositories/tailor_repository.dart';

// ===========================================================================
// REPOSITORY PROVIDER
// ===========================================================================

final tailorRepositoryProvider = Provider<TailorRepository>((ref) {
  return TailorRepository(ref.watch(supabaseClientProvider));
});

// ===========================================================================
// SEARCH QUERY PROVIDER
// ===========================================================================

/// Notifier untuk search query
class TailorSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
  void clear() => state = '';
}

final tailorSearchQueryProvider =
    NotifierProvider<TailorSearchQueryNotifier, String>(
  TailorSearchQueryNotifier.new,
);

// ===========================================================================
// LIST PROVIDER (dengan auto-reload saat search query berubah)
// ===========================================================================

/// Provider untuk List Tailor (dengan filter search otomatis)
final tailorsListProvider =
    FutureProvider.autoDispose<List<TailorModel>>((ref) async {
  final repository = ref.watch(tailorRepositoryProvider);
  final query = ref.watch(tailorSearchQueryProvider);

  // Jika query kosong, ambil semua. Jika ada, cari.
  if (query.isEmpty) {
    return repository.getAllTailors();
  } else {
    return repository.searchTailors(query);
  }
});

/// Provider untuk menghitung total tailor
final tailorCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repository = ref.watch(tailorRepositoryProvider);
  return repository.getTailorCount();
});

// ===========================================================================
// CRUD NOTIFIER
// ===========================================================================

/// Notifier untuk menangani Create/Update/Delete tailor
class TailorManagementNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Initial state void
  }

  void _log(String message, {String level = 'INFO'}) {
    final timestamp = DateTime.now().toString();
    // NOTE: Using print() to match existing codebase pattern.
    // Consider migrating to logger package for production.
    print('[$timestamp] [$level] TAILOR_MGMT_NOTIFIER: $message');
  }

  /// Create new tailor
  Future<TailorModel> createTailor({
    required String namaLengkap,
    required String email,
    required String noTelp,
    String? alamat,
    String? spesialisasi,
  }) async {
    _log('Creating new tailor: $namaLengkap ($email)');

    state = const AsyncValue.loading();

    try {
      final repository = ref.read(tailorRepositoryProvider);

      final tailor = await repository.createTailor(
        namaLengkap: namaLengkap,
        email: email,
        noTelp: noTelp,
        alamat: alamat,
        spesialisasi: spesialisasi,
      );

      // Invalidate list provider to refresh the list
      ref.invalidate(tailorsListProvider);
      ref.invalidate(tailorCountProvider);

      _log('Successfully created tailor: ${tailor.namaLengkap}');
      state = const AsyncValue.data(null);

      return tailor;
    } catch (e, st) {
      _log('Error creating tailor $namaLengkap: $e', level: 'ERROR');
      state = AsyncValue.error(e, st);
      rethrow; // Lempar ulang error agar UI bisa menangkap
    }
  }

  /// Update existing tailor
  Future<TailorModel> updateTailor({
    required String id,
    required String namaLengkap,
    required String email,
    required String noTelp,
    String? alamat,
    String? spesialisasi,
  }) async {
    _log('Updating tailor: id=$id, nama=$namaLengkap');

    state = const AsyncValue.loading();

    try {
      final repository = ref.read(tailorRepositoryProvider);

      final tailor = await repository.updateTailor(
        id: id,
        namaLengkap: namaLengkap,
        email: email,
        noTelp: noTelp,
        alamat: alamat,
        spesialisasi: spesialisasi,
      );

      // Invalidate list provider to refresh the list
      ref.invalidate(tailorsListProvider);

      _log('Successfully updated tailor: id=$id');
      state = const AsyncValue.data(null);

      return tailor;
    } catch (e, st) {
      _log('Error updating tailor $id: $e', level: 'ERROR');
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Delete tailor
  Future<void> deleteTailor(String id) async {
    _log('Deleting tailor: id=$id');

    state = const AsyncValue.loading();

    try {
      final repository = ref.read(tailorRepositoryProvider);

      await repository.deleteTailor(id);

      // Invalidate list provider to refresh the list
      ref.invalidate(tailorsListProvider);
      ref.invalidate(tailorCountProvider);

      _log('Successfully deleted tailor: id=$id');
      state = const AsyncValue.data(null);
    } catch (e, st) {
      _log('Error deleting tailor $id: $e', level: 'ERROR');
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

/// Provider tunggal untuk dipanggil di UI
final tailorManagementProvider =
    AsyncNotifierProvider<TailorManagementNotifier, void>(
  TailorManagementNotifier.new,
);
