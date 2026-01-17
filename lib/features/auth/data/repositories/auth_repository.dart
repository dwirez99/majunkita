import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  // Mengambil instance Supabase Client dari file core/api yang sudah kita buat
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  // ===========================================================================
  // 1. FUNGSI UTAMA: LOGIN & LOGOUT
  // ===========================================================================

  /// Login menggunakan Email dan Password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      // Supabase memberikan pesan error spesifik, kita tangkap di sini
      throw Exception(_mapAuthError(e.message));
    } catch (e) {
      throw Exception('Terjadi kesalahan saat login: $e');
    }
  }

  /// Logout (Keluar dari sesi)
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Gagal logout: $e');
    }
  }

  // ===========================================================================
  // 2. FUNGSI PENDUKUNG: SESSION & PROFILE
  // ===========================================================================

  /// Mengambil User yang sedang aktif (Session check)
  User? get currentUser => _supabase.auth.currentUser;

  /// Mengambil Data Profil Lengkap (Role, Nama, No HP) dari tabel 'profiles'
  /// Penting: Auth hanya menyimpan Email, data Role ada di tabel public.profiles
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final data =
          await _supabase
              .from('profiles')
              .select()
              .eq('id', user.id)
              .single(); // .single() memastikan kita cuma dapat 1 data
      return data;
    } catch (e) {
      // Jika profile belum ada (misal trigger database gagal), return null
      return null;
    }
  }

  // ===========================================================================
  // 3. FUNGSI ADMIN: CREATE USER (EDGE FUNCTION)
  // ===========================================================================

  /// Memanggil Edge Function untuk membuat user baru (Hanya untuk Admin/Manager)
  Future<void> createUserByAdmin({
    required String email,
    required String password,
    required String nama,
    required String role,
    required String noTelp,
  }) async {
    try {
      // Memanggil fungsi di Server (supabase/functions/create-user)
      final response = await _supabase.functions.invoke(
        'create-user',
        body: {
          'email': email,
          'password': password,
          'nama': nama,
          'role': role,
          'no_telp': noTelp,
        },
      );

      // Cek apakah Edge Function mengembalikan pesan error dalam JSON-nya
      final data = response.data;
      if (data is Map && data.containsKey('error')) {
        throw Exception(data['error']);
      }
    } on FunctionException catch (e) {
      // Menangkap error HTTP dari function (misal 403 Forbidden)
      final message =
          e.details?['error'] ??
          e.reasonPhrase ??
          'Terjadi kesalahan pada server';
      throw Exception(message);
    } catch (e) {
      throw Exception('Gagal membuat user: $e');
    }
  }

  // ===========================================================================
  // 4. HELPER: ERROR MAPPING (UX)
  // ===========================================================================

  /// Menerjemahkan error bahasa Inggris Supabase ke Bahasa Indonesia
  String _mapAuthError(String message) {
    if (message.toLowerCase().contains('invalid login credentials')) {
      return 'Email atau Password salah.';
    }
    if (message.toLowerCase().contains('email not confirmed')) {
      return 'Email belum diverifikasi. Silakan cek inbox Anda.';
    }
    return message; // Kembalikan pesan asli jika tidak dikenali
  }
}
