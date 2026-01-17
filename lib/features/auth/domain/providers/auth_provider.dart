import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/api/supabase_client_api.dart';
import '../../data/repositories/auth_repository.dart';

// 1. Provider untuk Supabase Client (Jika belum ada di file terpisah)
// Sebaiknya ini ditaruh di core/providers/core_providers.dart
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return supabaseClient;
});

// 2. Provider untuk AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});

// 3. Provider Stream User (Mendengarkan status Login/Logout Realtime)
// Ini "Jantung"-nya sesi aplikasi.
final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

// 4. Provider untuk mengambil Profil User Aktif (termasuk Role)
// Provider ini "pintar": Dia memantau authStateProvider.
// Kalau user login -> dia fetch profile. Kalau logout -> dia return null.
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  // Watch auth state
  final authState = ref.watch(authStateProvider);

  // Ambil data user dari stream
  final user = authState.value?.session?.user;

  if (user == null) return null; // Belum login

  // Jika login, gunakan repository untuk ambil data profile
  final authRepo = ref.watch(authRepositoryProvider);
  return await authRepo.getCurrentUserProfile();
});
