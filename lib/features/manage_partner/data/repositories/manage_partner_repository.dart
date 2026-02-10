// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/manage_partner_models.dart';

// Konstanta agar tidak typo string
class AppRoles {
  static const String admin = 'admin';
  static const String driver = 'driver';
}

class ManagePartnerRepository {
  final SupabaseClient _supabase;

  ManagePartnerRepository(this._supabase);

  // ===========================================================================
  // LOGGING HELPER
  // ===========================================================================

  void _log(String message, {String level = 'INFO'}) {
    final timestamp = DateTime.now().toString();
    print('[$timestamp] [$level] MANAGE_PARTNER: $message');
  }

  // ===========================================================================
  // GENERIC HELPER (FIXED & SINGLE SOURCE OF TRUTH)
  // ===========================================================================

  /// Private helper untuk fetch user berdasarkan role
  /// SUDAH DIPERBAIKI: Urutan .select() -> .ilike() -> .order()
  Future<List<T>> _getUsersByRole<T>({
    required String role,
    required T Function(Map<String, dynamic>) fromJson,
    String? searchQuery,
  }) async {
    try {
      // 1. Buat Query Dasar & Filter Wajib (eq)
      // Tipe variabel ini dinamis agar bisa chain method filter
      var query = _supabase.from('profiles').select().eq('role', role);

      // 2. Tambahkan Filter Search (ilike) JIKA ADA
      // Dilakukan SEBELUM .order() agar tipe datanya masih Builder
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('name', '%$searchQuery%');
      }

      // 3. Terakhir: Baru lakukan Order (Pengurutan) dan eksekusi (await)
      // .order() mengubah Builder menjadi TransformBuilder (Final step)
      final response = await query.order('name', ascending: true);

      return (response as List).map((json) => fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil data $role: $e');
    }
  }

  /// Private helper untuk membuat user via Edge Function
  Future<void> _createUserViaFunction({
    required String email,
    required String password,
    required String username,
    required String name,
    required String role,
    required String noTelp,
    String? address,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'create-user',
        body: {
          'email': email,
          'password': password,
          'username': username,
          'name': name,
          'role': role,
          'no_telp': noTelp,
          'address': address ?? '',
        },
      );

      if (response.status != 200) {
        throw Exception('Gagal: Status ${response.status}');
      }
    } catch (e) {
      throw Exception('Gagal membuat user: $e');
    }
  }

  // ===========================================================================
  // ADMIN OPERATIONS
  // ===========================================================================

  Future<List<Admin>> getAllAdmins() async {
    _log('Fetching all admins...');
    try {
      final result = await _getUsersByRole(
        role: AppRoles.admin,
        fromJson: Admin.fromJson,
      );
      _log('Successfully fetched ${result.length} admins');
      return result;
    } catch (e) {
      _log('Error fetching admins: $e', level: 'ERROR');
      rethrow;
    }
  }

  // KEMBALIKAN FUNGSI INI (Tadi hilang)
  Future<List<Admin>> searchAdmins(String query) async {
    _log('Searching admins with query: "$query"');
    try {
      final result = await _getUsersByRole(
        role: AppRoles.admin,
        fromJson: Admin.fromJson,
        searchQuery: query,
      );
      _log('Search found ${result.length} admin(s) matching "$query"');
      return result;
    } catch (e) {
      _log('Error searching admins: $e', level: 'ERROR');
      rethrow;
    }
  }

  Future<void> createAdmin({
    required String name,
    required String email,
    required String noTelp,
    required String password,
    String? address,
  }) async {
    _log('Creating new admin: $name ($email)');
    try {
      // Generate username from email (before @)
      final username = email.split('@')[0];

      await _createUserViaFunction(
        email: email,
        password: password,
        username: username,
        name: name,
        role: AppRoles.admin,
        noTelp: noTelp,
        address: address ?? '', // Tambahkan address jika diperlukan
      );
      _log('Successfully created admin: $name ($email)');
    } catch (e) {
      _log('Error creating admin $name: $e', level: 'ERROR');
      rethrow;
    }
  }

  // ===========================================================================
  // DRIVER OPERATIONS
  // ===========================================================================

  Future<List<Driver>> getAllDrivers() async {
    _log('Fetching all drivers...');
    try {
      final result = await _getUsersByRole(
        role: AppRoles.driver,
        fromJson: Driver.fromJson,
      );
      _log('Successfully fetched ${result.length} drivers');
      return result;
    } catch (e) {
      _log('Error fetching drivers: $e', level: 'ERROR');
      rethrow;
    }
  }

  Future<List<Driver>> searchDrivers(String query) async {
    _log('Searching drivers with query: "$query"');
    try {
      final result = await _getUsersByRole(
        role: AppRoles.driver,
        fromJson: Driver.fromJson,
        searchQuery: query,
      );
      _log('Search found ${result.length} driver(s) matching "$query"');
      return result;
    } catch (e) {
      _log('Error searching drivers: $e', level: 'ERROR');
      rethrow;
    }
  }

  Future<void> createDriver({
    required String name,
    required String email,
    required String noTelp,
    required String password,
    String? address,
  }) async {
    _log('Creating new driver: $name ($email)');
    try {
      // Generate username from email (before @)
      final username = email.split('@')[0];

      await _createUserViaFunction(
        email: email,
        password: password,
        username: username,
        name: name,
        role: AppRoles.driver,
        noTelp: noTelp,
        address: address ?? '', // Tambahkan address jika diperlukan
      );
      _log('Successfully created driver: $name ($email)');
    } catch (e) {
      _log('Error creating driver $name: $e', level: 'ERROR');
      rethrow;
    }
  }

  // ===========================================================================
  // SHARED / UPDATE / DELETE
  // ===========================================================================

  Future<void> updateUser({
    required String id,
    required String name,
    String? username,
    required String email,
    required String noTelp,
    String? password,
    String? role,
    String? address,
  }) async {
    _log('Updating user: id=$id, name=$name, email=$email, address=${address ?? 'N/A'}');
    try {
      // Build request body
      final body = <String, dynamic>{
        'user_id': id,
        'name': name,
        'email': email,
        'no_telp': noTelp,
      };

      if (username != null && username.isNotEmpty) {
        body['username'] = username;
      }

      if (password != null && password.isNotEmpty) {
        body['password'] = password;
      }

      if (role != null && role.isNotEmpty) {
        body['role'] = role;
      }

      if (address != null && address.isNotEmpty) {
        body['address'] = address;
      }

      // Call Edge Function to update user
      final response = await _supabase.functions.invoke(
        'update-user',
        body: body,
      );

      if (response.status != 200) {
        throw Exception('Gagal mengupdate user: Status ${response.status}');
      }

      _log('Successfully updated user: id=$id, nama=$name');
    } catch (e) {
      _log('Error updating user $id: $e', level: 'ERROR');
      rethrow;
    }
  }

  Future<void> deleteUser(String id) async {
    _log('Deleting user: id=$id');
    try {
      // Call Edge Function to delete user from auth.users
      // This will also cascade delete from profiles table
      final response = await _supabase.functions.invoke(
        'delete-user',
        body: {'user_id': id},
      );

      if (response.status != 200) {
        throw Exception('Gagal menghapus user: Status ${response.status}');
      }

      _log('Successfully deleted user: id=$id');
    } catch (e) {
      _log('Error deleting user $id: $e', level: 'ERROR');
      rethrow;
    }
  }
}
