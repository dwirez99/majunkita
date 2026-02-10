import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/manage_partner_providers.dart';

class StaffFormDialog extends ConsumerStatefulWidget {
  /// Role: 'admin' atau 'driver' (Gunakan AppRoles constant biar aman)
  final String role;

  /// Jika null, berarti mode CREATE. Jika ada isi, berarti mode EDIT.
  /// Kita pakai dynamic agar bisa menerima object Admin ataupun Driver
  final dynamic staffToEdit;

  const StaffFormDialog({super.key, required this.role, this.staffToEdit});

  @override
  ConsumerState<StaffFormDialog> createState() => _StaffFormDialogState();
}

class _StaffFormDialogState extends ConsumerState<StaffFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _noTelpController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _passwordController;

  bool get _isEdit => widget.staffToEdit != null;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller dengan data jika mode Edit
    _nameController = TextEditingController(
      text: widget.staffToEdit?.name ?? '',
    );
    _usernameController = TextEditingController(
      text: widget.staffToEdit?.username ?? '',
    );
    _noTelpController = TextEditingController(
      text: widget.staffToEdit?.noTelp ?? '',
    );
    _emailController = TextEditingController(
      text: widget.staffToEdit?.email ?? '',
    );
    // Cek apakah model punya alamat (handle null safety)
    _addressController = TextEditingController(
      text: widget.staffToEdit?.address ?? '',
    );
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _noTelpController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ubah judul otomatis berdasarkan Role & Mode
    final String roleLabel = widget.role == AppRoles.admin ? 'Admin' : 'Driver';
    final String title =
        _isEdit ? 'Edit Data $roleLabel' : 'Tambah $roleLabel Baru';

    // Dengarkan state loading dari provider gabungan
    final asyncState = ref.watch(staffManagementProvider);
    final isLoading = asyncState.isLoading;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color:
              Colors.white, // Ganti putih biar lebih clean, atau sesuaikan tema
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Title
                Center(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Nama
                _buildLabel('Nama Lengkap'),
                _buildTextField(
                  controller: _nameController,
                  hint: 'Masukkan nama lengkap',
                  validator: (v) => v!.isEmpty ? 'Nama wajib diisi' : null,
                ),

                // Username
                _buildLabel('Username'),
                _buildTextField(
                  controller: _usernameController,
                  hint: 'Masukkan Username',
                  validator: (v) => v!.isEmpty ? 'Username wajib diisi' : null,
                ),

                // No Telp
                _buildLabel('Nomor'),
                _buildTextField(
                  controller: _noTelpController,
                  hint: '08xxxxxxxx',
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.isEmpty ? 'Nomor wajib diisi' : null,
                ),

                // Email (Readonly jika Edit)
                _buildLabel('Email'),
                _buildTextField(
                  controller: _emailController,
                  hint: 'email@gmail.com',
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isEdit, // Tidak boleh ganti email sembarangan
                  validator: (v) {
                    if (!_isEdit && (v == null || v.isEmpty)) {
                      return 'Email wajib diisi';
                    }
                    if (!_isEdit && !v!.contains('@')) {
                      return 'Email tidak valid';
                    }
                    return null;
                  },
                ),

                // Password (Hanya muncul saat Tambah Baru)
                if (!_isEdit) ...[
                  _buildLabel('Password '),
                  _buildTextField(
                    controller: _passwordController,
                    hint: 'Minimal 6 karakter',
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password wajib diisi';
                      if (v.length < 6) return 'Password terlalu pendek';
                      return null;
                    },
                  ),
                ],

                // Password (Optional saat Edit - untuk reset password)
                if (_isEdit) ...[
                  _buildLabel('Password Baru (Opsional)'),
                  _buildTextField(
                    controller: _passwordController,
                    hint: 'Kosongkan jika tidak ingin mengubah password',
                    obscureText: true,
                    validator: (v) {
                      // Hanya validasi jika diisi
                      if (v != null && v.isNotEmpty && v.length < 6) {
                        return 'Password minimal 6 karakter';
                      }
                      return null;
                    },
                  ),
                ],

                // Alamat
                _buildLabel('Alamat Domisili'),
                _buildTextField(
                  controller: _addressController,
                  hint: 'Alamat lengkap...',
                  maxLines: 3,
                  validator: (v) => v!.isEmpty ? 'Alamat wajib diisi' : null,
                ),

                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed:
                            isLoading ? null : () => Navigator.pop(context),
                        child: const Text(
                          'Batal',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              widget.role == AppRoles.admin
                                  ? Colors.blue[800] // Admin warna Biru
                                  : Colors.orange[800], // Driver warna Orange
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child:
                            isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(
                                  _isEdit ? 'Simpan Perubahan' : 'Buat Akun',
                                ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper Widget biar kodingan UI rapi
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? hint,
    bool obscureText = false,
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: enabled ? Colors.grey[100] : Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: validator,
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // Panggil Provider
    final notifier = ref.read(staffManagementProvider.notifier);

    try {
      if (_isEdit) {
        // --- LOGIKA UPDATE ---
        await notifier.updateStaff(
          id: widget.staffToEdit!.id,
          name: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          noTelp: _noTelpController.text.trim(),
          address: _addressController.text.trim(),
          role: widget.role, // Penting agar list yang direfresh sesuai
          password: _passwordController.text.trim().isEmpty
              ? null
              : _passwordController.text.trim(),
        );
        if (mounted) _showSuccess('Data ${widget.role} berhasil diperbarui!');
      } else {
        // --- LOGIKA CREATE ---
        await notifier.createStaff(
          name: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          noTelp: _noTelpController.text.trim(),
          password: _passwordController.text,
          role: widget.role, // 'admin' atau 'driver'
          address: _addressController.text.trim(),
        );
        if (mounted) _showSuccess('Akun ${widget.role} baru berhasil dibuat!');
      }

      if (mounted) Navigator.pop(context); // Tutup dialog
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }
}
