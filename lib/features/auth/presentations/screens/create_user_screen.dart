import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/api/supabase_client_api.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(); // Password awal
  final _phoneController = TextEditingController();

  String _selectedRole = 'driver'; // Default role
  bool _isLoading = false;

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Panggil Edge Function 'create-user'
      final response = await supabaseClient.functions.invoke(
        'create-user',
        body: {
          'email': _emailController.text,
          'password': _passwordController.text,
          'nama': _nameController.text,
          'role': _selectedRole,
          'no_telp': _phoneController.text,
        },
      );

      // Supabase Functions melempar error via exception jika status != 200
      // Tapi kita cek payload untuk memastikan
      final data = response.data;

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User berhasil dibuat!')));
        Navigator.pop(context); // Kembali ke dashboard
      }
    } catch (e) {
      if (mounted) {
        // Parsing error message biar enak dibaca
        String errorMessage = e.toString();
        if (e is FunctionException) {
          errorMessage =
              e.details?['error'] ?? e.reasonPhrase ?? 'Terjadi kesalahan';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Pengguna Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator:
                    (val) => val!.contains('@') ? null : 'Email tidak valid',
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password Awal',
                  helperText:
                      'Berikan password ini ke user, minta mereka segera ganti.',
                ),
                validator:
                    (val) => val!.length < 6 ? 'Minimal 6 karakter' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Role / Jabatan'),
                items: const [
                  DropdownMenuItem(
                    value: 'driver',
                    child: Text('Driver (Supir)'),
                  ),
                  DropdownMenuItem(
                    value: 'partner_pabrik',
                    child: Text('Partner Pabrik'),
                  ),
                  DropdownMenuItem(
                    value: 'admin',
                    child: Text('Admin / Manager'),
                  ),
                ],
                onChanged: (val) => setState(() => _selectedRole = val!),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Nomor WhatsApp'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Buat Akun'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
