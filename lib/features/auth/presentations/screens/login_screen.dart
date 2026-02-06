import 'package:flutter/material.dart';
import '../../../../core/api/supabase_client_api.dart';
import '../../data/repositories/auth_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 1. Inisialisasi Repository & Controller
  final _authRepo = AuthRepository(supabaseClient);
  final _formKey = GlobalKey<FormState>();

  final _identifierController = TextEditingController(); // Email atau Username
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
        identifier:
            _identifierController.text.trim(), // Bisa email atau username
        password: _passwordController.text,
      );

      // B. Login berhasil - AuthWrapper akan otomatis handle navigation
      // Tidak perlu manual navigation karena sudah ada auth state listener
      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login berhasil!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
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

                // INPUT EMAIL ATAU USERNAME
                TextFormField(
                  controller: _identifierController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'Email atau Username',
                    hintText: 'Masukkan email atau username',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email atau Username wajib diisi';
                    }
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
                    if (value == null || value.isEmpty) {
                      return 'Password wajib diisi';
                    }
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
