import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../domain/providers/manage_partner_providers.dart';

class PersonalInfoEditDialog extends ConsumerStatefulWidget {
  const PersonalInfoEditDialog({super.key});

  @override
  ConsumerState<PersonalInfoEditDialog> createState() =>
      _PersonalInfoEditDialogState();
}

class _PersonalInfoEditDialogState
    extends ConsumerState<PersonalInfoEditDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _noTelpController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _passwordController;

  Map<String, dynamic>? _profile;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _noTelpController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _passwordController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(userProfileProvider).value;
      if (profile != null && mounted) {
        setState(() {
          _profile = profile;
          _nameController.text =
              (profile['name'] ?? profile['nama_lengkap'] ?? '').toString();
          _usernameController.text = (profile['username'] ?? '').toString();
          _noTelpController.text = (profile['no_telp'] ?? '').toString();
          _emailController.text = (profile['email'] ?? '').toString();
          _addressController.text = (profile['address'] ?? '').toString();
        });
      }
    });
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
    final profileAsync = ref.watch(userProfileProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(20),
        child: profileAsync.when(
          loading:
              () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
          error:
              (e, _) => SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'Gagal memuat profil: $e',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          data: (profile) {
            if (profile == null) {
              return const SizedBox(
                height: 200,
                child: Center(child: Text('Profil tidak ditemukan.')),
              );
            }

            _profile ??= profile;
            if (_nameController.text.isEmpty && _emailController.text.isEmpty) {
              _nameController.text =
                  (profile['name'] ?? profile['nama_lengkap'] ?? '').toString();
              _usernameController.text = (profile['username'] ?? '').toString();
              _noTelpController.text = (profile['no_telp'] ?? '').toString();
              _emailController.text = (profile['email'] ?? '').toString();
              _addressController.text = (profile['address'] ?? '').toString();
            }

            return SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'Edit Informasi Pribadi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Nama Lengkap'),
                    _buildTextField(
                      controller: _nameController,
                      hint: 'Masukkan nama lengkap',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Nama wajib diisi';
                        return null;
                      },
                    ),

                    _buildLabel('Username'),
                    _buildTextField(
                      controller: _usernameController,
                      hint: 'Masukkan username',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Username wajib diisi';
                        return null;
                      },
                    ),

                    _buildLabel('Nomor Telepon'),
                    _buildTextField(
                      controller: _noTelpController,
                      hint: '62xxxxxxxxxxx',
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        final value = (v ?? '').trim();
                        if (value.isEmpty) return 'Nomor telepon wajib diisi';
                        if (!value.startsWith('62'))
                          return 'Nomor telepon harus diawali 62';
                        if (value.length < 10)
                          return 'Nomor telepon terlalu pendek';
                        return null;
                      },
                    ),

                    _buildLabel('Email'),
                    _buildTextField(
                      controller: _emailController,
                      hint: 'email@gmail.com',
                      keyboardType: TextInputType.emailAddress,
                      enabled: false,
                    ),

                    _buildLabel('Alamat'),
                    _buildTextField(
                      controller: _addressController,
                      hint: 'Alamat lengkap...',
                      maxLines: 3,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Alamat wajib diisi';
                        return null;
                      },
                    ),

                    _buildLabel('Password Baru (Opsional)'),
                    _buildTextField(
                      controller: _passwordController,
                      hint: 'Kosongkan jika tidak ingin mengubah password',
                      obscureText: true,
                      validator: (v) {
                        if (v != null && v.isNotEmpty && v.length < 6) {
                          return 'Password minimal 6 karakter';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed:
                                _isSubmitting
                                    ? null
                                    : () => Navigator.pop(context),
                            child: const Text(
                              'Batal',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _handleSave,
                            child:
                                _isSubmitting
                                    ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : const Text('Simpan'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 14),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
        filled: true,
        fillColor: enabled ? Colors.grey.shade100 : Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      validator: validator,
      onChanged:
          keyboardType == TextInputType.phone
              ? (value) {
                final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
                String normalized = digitsOnly;

                if (digitsOnly.startsWith('0')) {
                  normalized = '62${digitsOnly.substring(1)}';
                } else if (digitsOnly.startsWith('8')) {
                  normalized = '62$digitsOnly';
                } else if (!digitsOnly.startsWith('62') &&
                    digitsOnly.isNotEmpty) {
                  normalized = '62$digitsOnly';
                }

                if (normalized != value) {
                  controller.value = TextEditingValue(
                    text: normalized,
                    selection: TextSelection.collapsed(
                      offset: normalized.length,
                    ),
                  );
                }
              }
              : null,
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final profile = _profile ?? ref.read(userProfileProvider).value;
    if (profile == null) {
      _showError('Profil tidak ditemukan.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final notifier = ref.read(staffManagementProvider.notifier);

      final id = (profile['id'] ?? '').toString();
      final role = (profile['role'] ?? '').toString();
      if (id.isEmpty || role.isEmpty) {
        throw Exception('Data profil tidak lengkap (id/role).');
      }

      await notifier.updateMyProfile(
        id: id,
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        noTelp: _normalizePhoneNumber(_noTelpController.text),
        address: _addressController.text.trim(),
        role: role,
        password:
            _passwordController.text.trim().isEmpty
                ? null
                : _passwordController.text.trim(),
      );

      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Informasi pribadi berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showError('Gagal memperbarui profil: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _normalizePhoneNumber(String input) {
    final digitsOnly = input.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.startsWith('62')) return digitsOnly;
    if (digitsOnly.startsWith('0') && digitsOnly.length > 1) {
      return '62${digitsOnly.substring(1)}';
    }
    if (digitsOnly.startsWith('8')) return '62$digitsOnly';
    return digitsOnly.isEmpty ? digitsOnly : '62$digitsOnly';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
