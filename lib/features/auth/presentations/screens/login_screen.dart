import 'package:flutter/material.dart';
import '../../../../core/api/supabase_client_api.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../Dashboard/presentations/screens/dashboard_manager_screen.dart';

// Placeholder untuk Dashboard lain (Nanti kita buat)
// import '../../../Dashboard/presentations/screens/dashboard_driver_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 1. Inisialisasi Repository & Controller
  final _authRepo = AuthRepository(supabaseClient);
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // State Variable
  bool _isLoading = false;
  bool _obscurePassword = true;

  // 2. LOGIKA LOGIN & NAVIGASI
  Future<void> _handleLogin() async {
    // Validasi Form Dasar
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // A. Proses Autentikasi ke Supabase Auth
      await _authRepo.signIn(
        email: _emailController.text.trim(), // Trim spasi bahaya
        password: _passwordController.text,
      );

      // B. Ambil Profil untuk Cek Role
      // (Kita butuh tahu dia siapa: Manager? Driver?)
      final profile = await _authRepo.getCurrentUserProfile();

      if (!mounted) return;

      if (profile == null) {
        throw Exception('Profil pengguna tidak ditemukan. Hubungi Admin.');
      }

      final role = profile['role'] as String?;

      // C. Navigasi Berdasarkan Role (THE ROUTER)
      _navigateBasedOnRole(role);
    } catch (e) {
      if (!mounted) return;
      // Tampilkan Error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateBasedOnRole(String? role) {
    Widget nextScreen;

    // Normalisasi string (jaga-jaga ada huruf besar)
    switch (role?.toLowerCase()) {
      case 'admin':
      case 'manager':
        nextScreen = const DashboardManagerScreen();
        break;
      case 'driver':
        // TODO: Ganti ke DashboardDriverScreen nanti
        nextScreen = const Scaffold(
          body: Center(child: Text("Dashboard Driver (Coming Soon)")),
        );
        break;
      case 'partner_pabrik':
        // TODO: Ganti ke DashboardPartnerScreen nanti
        nextScreen = const Scaffold(
          body: Center(child: Text("Dashboard Partner (Coming Soon)")),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Role tidak dikenali. Akses ditolak.')),
        );
        return;
    }

    // Pindah halaman & Hapus riwayat login (agar tidak bisa di-back)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // LOGO & JUDUL
                const Icon(Icons.recycling, size: 80, color: Colors.green),
                const SizedBox(height: 16),
                const Text(
                  'MAJUNKITA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const Text(
                  'Sistem Manajemen Distribusi',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 48),

                // INPUT EMAIL
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Email wajib diisi';
                    if (!value.contains('@')) return 'Email tidak valid';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // INPUT PASSWORD
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed:
                          () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Password wajib diisi';
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // TOMBOL LOGIN
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700], // Warna brand (Eco)
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text(
                            'MASUK',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),

                const SizedBox(height: 24),

                // INFO FOOTER
                const Text(
                  'Jika lupa password, hubungi Manager Operasional\nuntuk reset akun.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
