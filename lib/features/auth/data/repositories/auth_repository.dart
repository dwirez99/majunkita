import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  // Mengambil instance Supabase Client dari file core/api yang sudah kita buat
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  /// Login menggunakan Email atau Username dan Password
  /// Identifier bisa berupa:
  /// - Email (jika mengandung @)
  /// - Username (nama dari tabel profiles)
  Future<AuthResponse> signIn({
    required String identifier, // Bisa email atau username
    required String password,
  }) async {
    try {
      String email;

      // Cek apakah identifier adalah email (mengandung @) atau username
      if (identifier.contains('@')) {
        // Jika mengandung @, langsung gunakan sebagai email
        email = identifier;
        print('[AUTH_REPO] Using email directly: $email');
      } else {
        // Jika tidak mengandung @, cari email berdasarkan username (nama)
        email = await _getEmailByUsername(identifier);
        print('[AUTH_REPO] Found email for username "$identifier": $email');
      }

      print('[AUTH_REPO] Attempting login with email: $email');
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      print('[AUTH_REPO] Login successful!');
      return response;
    } on AuthException catch (e) {
      // Supabase memberikan pesan error spesifik, kita tangkap di sini
      throw Exception(_mapAuthError(e.message));
    } catch (e) {
      throw Exception('Terjadi kesalahan saat login: $e');
    }
  }

  /// Helper: Mengambil email dari username (nama)
  /// Mendukung pencarian case-insensitive untuk UX yang lebih baik
  /// Username harus unik di database (ada constraint)
  Future<String> _getEmailByUsername(String username) async {
    try {
      // Menggunakan RPC function yang sudah dibuat di database
      // Lebih aman dan efisien daripada query langsung
      print('[AUTH_REPO] Looking up username: "$username"');
      
      // Don't convert to lowercase - database function handles case-insensitive comparison
      final email = await _supabase.rpc(
        'get_email_by_username',
        params: {'_username': username},
      );

      print('[AUTH_REPO] RPC response for username "$username": $email');

      if (email == null || email.toString().isEmpty) {
        print('[AUTH_REPO] Username not found: $username');
        throw Exception('Username tidak ditemukan');
      }

      print('[AUTH_REPO] Successfully found email for username "$username": $email');
      return email.toString();
    } catch (e) {
      // Jika terjadi error atau username tidak ditemukan
      print('[AUTH_REPO] Error looking up username "$username": $e');
      if (e.toString().contains('Username tidak ditemukan')) {
        rethrow;
      }
      throw Exception('Username tidak ditemukan');
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
    required String namaLengkap,
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
          'nama_lengkap': namaLengkap,
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
