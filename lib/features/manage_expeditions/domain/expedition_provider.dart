// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/supabase_client_api.dart';
import '../data/models/expedition_model.dart';
import '../data/repositories/expedition_repository.dart';

// ===========================================================================
// REPOSITORY PROVIDER
// ===========================================================================

/// Provider untuk ExpeditionRepository, menerima SupabaseClient sebagai dependency
final expeditionRepositoryProvider = Provider<ExpeditionRepository>((ref) {
  return ExpeditionRepository(ref.watch(supabaseClientProvider));
});

// ===========================================================================
// LIST PROVIDER
// ===========================================================================

/// FutureProvider untuk mengambil daftar expedisi dari database
final expeditionListProvider =
    FutureProvider.autoDispose<List<ExpeditionModel>>((ref) async {
  final repository = ref.watch(expeditionRepositoryProvider);
  return repository.getExpeditions();
});

// ===========================================================================
// DRIVER LIST PROVIDER
// ===========================================================================

/// Simple data class untuk menampung id dan nama driver di dropdown form
class DriverOption {
  final String id;
  final String name;
  DriverOption({required this.id, required this.name});
}

/// FutureProvider untuk mengambil daftar driver dari tabel profiles
final driverOptionsProvider =
    FutureProvider.autoDispose<List<DriverOption>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final response = await supabase
      .from('profiles')
      .select('id, name')
      .eq('role', 'driver')
      .order('name', ascending: true);

  return (response as List)
      .map(
        (json) => DriverOption(
          id: json['id'] as String,
          name: (json['name'] as String?) ?? 'Tanpa Nama',
        ),
      )
      .toList();
});

// ===========================================================================
// CRUD NOTIFIER
// ===========================================================================

/// Notifier untuk menangani operasi Create dan Delete expedisi
/// Menggunakan AsyncNotifier agar bisa menampilkan loading state di UI
class ManageExpeditionNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // State awal kosong, tidak ada aksi yang dilakukan
  }

  void _log(String message, {String level = 'INFO'}) {
    final timestamp = DateTime.now().toString();
    print('[$timestamp] [$level] EXPEDITION_NOTIFIER: $message');
  }

  /// Membuat expedisi baru dengan upload gambar bukti pengiriman
  Future<void> createExpedition(ExpeditionModel data, File imageFile) async {
    _log('Creating expedition to ${data.destination}...');

    // Set state ke loading agar UI menampilkan indikator proses
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(expeditionRepositoryProvider);

      // Panggil repository untuk create + upload gambar
      await repository.createExpedition(data, imageFile);

      // Invalidate list provider agar daftar expedisi diperbarui otomatis
      ref.invalidate(expeditionListProvider);

      _log('Successfully created expedition');
      state = const AsyncValue.data(null);
    } catch (e, st) {
      _log('Error creating expedition: $e', level: 'ERROR');
      state = AsyncValue.error(e, st);
      rethrow; // Lempar ulang agar UI bisa menampilkan pesan error
    }
  }

  /// Menghapus expedisi dari database dan file dari storage
  Future<void> deleteExpedition(String id, String imageUrl) async {
    _log('Deleting expedition: id=$id');

    // Set state ke loading agar UI menampilkan indikator proses
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(expeditionRepositoryProvider);

      // Panggil repository untuk delete data dan file
      await repository.deleteExpedition(id, imageUrl);

      // Invalidate list provider agar daftar expedisi diperbarui otomatis
      ref.invalidate(expeditionListProvider);

      _log('Successfully deleted expedition: id=$id');
      state = const AsyncValue.data(null);
    } catch (e, st) {
      _log('Error deleting expedition $id: $e', level: 'ERROR');
      state = AsyncValue.error(e, st);
      rethrow; // Lempar ulang agar UI bisa menampilkan pesan error
    }
  }
}

/// Provider tunggal untuk diakses di UI
final manageExpeditionNotifierProvider =
    AsyncNotifierProvider<ManageExpeditionNotifier, void>(
  ManageExpeditionNotifier.new,
);

// ===========================================================================
// WEIGHT PER SACK PROVIDERS
// ===========================================================================

/// FutureProvider untuk membaca nilai weight_per_sack dari app_settings
final weightPerSackProvider = FutureProvider<int>((ref) {
  return ref.watch(expeditionRepositoryProvider).getWeightPerSack();
});

// ===========================================================================
// AVAILABLE STOCK PROVIDER
// ===========================================================================

/// FutureProvider.autoDispose untuk membaca stok majun tersedia dari RPC.
/// autoDispose agar stok di-refresh setiap kali form dibuka.
final availableStockProvider = FutureProvider.autoDispose<double>((ref) {
  return ref.read(expeditionRepositoryProvider).getAvailableStock();
});

/// Notifier untuk memperbarui weight_per_sack di app_settings
class UpdateWeightPerSackNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> updateWeight(int newWeight) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(expeditionRepositoryProvider)
          .updateWeightPerSack(newWeight);
      ref.invalidate(weightPerSackProvider);
    });
    if (state.hasError) throw state.error!;
  }
}

final updateWeightPerSackProvider =
    AsyncNotifierProvider<UpdateWeightPerSackNotifier, void>(
  UpdateWeightPerSackNotifier.new,
);
