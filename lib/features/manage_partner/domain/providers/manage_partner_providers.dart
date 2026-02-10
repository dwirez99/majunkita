// ignore_for_file: avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/supabase_client_api.dart';
import '../../data/models/manage_partner_models.dart';
import '../../data/repositories/manage_partner_repository.dart';

// Definisi Role agar tidak typo
class AppRoles {
  static const String manager = 'manager';
  static const String admin = 'admin';
  static const String driver = 'driver';
}

// ===========================================================================
// REPOSITORY & PERMISSION PROVIDER
// ===========================================================================

final managePartnerRepositoryProvider = Provider<ManagePartnerRepository>((
  ref,
) {
  return ManagePartnerRepository(ref.watch(supabaseClientProvider));
});

/// Provider untuk mengecek apakah user yang sedang login adalah MANAGER
final isManagerProvider = Provider<bool>((ref) {
  final user = ref.watch(supabaseClientProvider).auth.currentUser;
  // Kita ambil role dari user_metadata (pastikan saat login metadata role tersimpan)
  final role = user?.userMetadata?['role'] as String?;
  return role == AppRoles.manager;
});

// ===========================================================================
// LIST & SEARCH PROVIDERS (GENERIC)
// ===========================================================================

/// Notifier untuk search query (Bisa dipakai untuk admin maupun driver)
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String query) => state = query;
  void clear() => state = '';
}

// Kita buat instance terpisah agar state search Admin & Driver tidak bentrok
final adminSearchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);
final driverSearchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

/// Provider untuk List Admin (dengan filter search otomatis)
final adminsListProvider = FutureProvider.autoDispose<List<Admin>>((
  ref,
) async {
  final repository = ref.watch(managePartnerRepositoryProvider);
  final query = ref.watch(adminSearchQueryProvider);

  // Jika query kosong, ambil semua. Jika ada, cari.
  if (query.isEmpty) {
    return repository.getAllAdmins();
  } else {
    return repository.searchAdmins(query);
  }
});

/// Provider untuk List Driver (dengan filter search otomatis)
final driversListProvider = FutureProvider.autoDispose<List<Driver>>((
  ref,
) async {
  final repository = ref.watch(managePartnerRepositoryProvider);
  final query = ref.watch(driverSearchQueryProvider);

  if (query.isEmpty) {
    return repository.getAllDrivers();
  } else {
    return repository.searchDrivers(query);
  }
});

// ===========================================================================
// CRUD NOTIFIER (GABUNGAN ADMIN & DRIVER)
// ===========================================================================

/// Satu Notifier untuk menangani Create/Update/Delete karyawan apapun
// ... imports

class StaffManagementNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Initial state void
  }

  void _log(String message, {String level = 'INFO'}) {
    final timestamp = DateTime.now().toString();
    print('[$timestamp] [$level] STAFF_MGMT_NOTIFIER: $message');
  }

  void _checkManagerPermission() {
    final isManager = ref.read(isManagerProvider);
    if (!isManager) {
      _log(
        'Permission denied: Non-manager trying to access staff management',
        level: 'WARN',
      );
      throw Exception(
        'Akses Ditolak: Hanya Manager yang boleh mengelola data.',
      );
    }
    _log('Manager permission verified');
  }

  // --- PERBAIKAN DI SINI ---
  Future<void> createStaff({
    required String name,
    required String username,
    required String email,
    required String noTelp,
    required String password,
    required String role,
    String? address,
  }) async {
    _checkManagerPermission();
    _log(
      'Creating new $role: $name (username: $username, email: $email)',
    );

    state = const AsyncValue.loading();

    // Jangan pakai AsyncValue.guard mentah-mentah jika butuh feedback di UI
    // Kita pakai try-catch manual agar bisa rethrow
    try {
      final repository = ref.read(managePartnerRepositoryProvider);

      if (role == AppRoles.admin) {
        await repository.createAdmin(
          name: name,
          email: email,
          noTelp: noTelp,
          password: password,
          address: address,
        );
        ref.invalidate(adminsListProvider);
      } else if (role == AppRoles.driver) {
        await repository.createDriver(
          name: name,
          email: email,
          noTelp: noTelp,
          password: password,
          address: address,
        );
        ref.invalidate(driversListProvider);
      }

      // Jika berhasil, set state data
      _log('Successfully created $role: $name');
      state = const AsyncValue.data(null);
    } catch (e, st) {
      // 1. Simpan error ke state (agar UI bisa baca status error)
      _log('Error creating $role $name: $e', level: 'ERROR');
      state = AsyncValue.error(e, st);

      // 2. LEMPAR ULANG errornya agar UI (Dialog) tahu ini gagal!
      rethrow;
    }
  }

  // Lakukan hal yang sama untuk updateStaff dan deleteStaff
  Future<void> updateStaff({
    required String id,
    required String name,
    String? username,
    required String email,
    required String noTelp,
    String? address,
    required String role,
    String? password,
  }) async {
    _checkManagerPermission();
    _log('Updating $role: id=$id, name=$name, email=$email, address=${address ?? 'N/A'}');
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(managePartnerRepositoryProvider);
      await repository.updateUser(
        id: id,
        name: name,
        username: username,
        email: email,
        noTelp: noTelp,
        address: address,
        password: password,
        role: role,
      );

      if (role == AppRoles.admin) ref.invalidate(adminsListProvider);
      if (role == AppRoles.driver) ref.invalidate(driversListProvider);

      _log('Successfully updated $role: id=$id');
      state = const AsyncValue.data(null);
    } catch (e, st) {
      _log('Error updating $role $id: $e', level: 'ERROR');
      state = AsyncValue.error(e, st);
      rethrow; // <--- PENTING
    }
  }

  Future<void> deleteStaff({required String id, required String role}) async {
    _checkManagerPermission();
    _log('Deleting $role: id=$id');
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(managePartnerRepositoryProvider);
      await repository.deleteUser(id);

      if (role == AppRoles.admin) ref.invalidate(adminsListProvider);
      if (role == AppRoles.driver) ref.invalidate(driversListProvider);

      _log('Successfully deleted $role: id=$id');
      state = const AsyncValue.data(null);
    } catch (e, st) {
      _log('Error deleting $role $id: $e', level: 'ERROR');
      state = AsyncValue.error(e, st);
      rethrow; // <--- PENTING
    }
  }
}

// Provider tunggal untuk dipanggil di UI
final staffManagementProvider =
    AsyncNotifierProvider<StaffManagementNotifier, void>(
      StaffManagementNotifier.new,
    );
