import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/factory_models.dart';
import '../../domain/providers/factory_provider.dart';

class FactoryFormDialog extends ConsumerStatefulWidget {
  /// Jika null, berarti mode CREATE. Jika ada isi, berarti mode EDIT.
  final FactoryModel? factoryToEdit;

  const FactoryFormDialog({super.key, this.factoryToEdit});

  @override
  ConsumerState<FactoryFormDialog> createState() => _FactoryFormDialogState();
}

class _FactoryFormDialogState extends ConsumerState<FactoryFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _factoryNameController;
  late TextEditingController _addressController;
  late TextEditingController _noTelpController;

  bool get _isEdit => widget.factoryToEdit != null;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller dengan data jika mode Edit
    _factoryNameController = TextEditingController(
      text: widget.factoryToEdit?.factoryName ?? '',
    );
    _addressController = TextEditingController(
      text: widget.factoryToEdit?.address ?? '',
    );
    _noTelpController = TextEditingController(
      text: widget.factoryToEdit?.noTelp ?? '',
    );
  }

  @override
  void dispose() {
    _factoryNameController.dispose();
    _addressController.dispose();
    _noTelpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String title =
        _isEdit ? 'Edit Data Pabrik' : 'Tambah Pabrik Baru';

    // Dengarkan state loading dari provider gabungan
    final asyncState = ref.watch(factoryManagementProvider);
    final isLoading = asyncState.isLoading;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
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

                // Nama Pabrik
                _buildLabel('Nama Pabrik'),
                _buildTextField(
                  controller: _factoryNameController,
                  hint: 'Masukkan nama pabrik',
                  validator: (v) => v!.isEmpty ? 'Nama pabrik wajib diisi' : null,
                ),

                // Alamat
                _buildLabel('Alamat Pabrik'),
                _buildTextField(
                  controller: _addressController,
                  hint: 'Alamat lengkap pabrik...',
                  maxLines: 3,
                  validator: (v) => v!.isEmpty ? 'Alamat wajib diisi' : null,
                ),

                // No Telepon
                _buildLabel('Nomor Telepon'),
                _buildTextField(
                  controller: _noTelpController,
                  hint: '08xxxxxxxx',
                  keyboardType: TextInputType.phone,
                  validator:
                      (v) => v!.isEmpty ? 'Nomor telepon wajib diisi' : null,
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
                          backgroundColor: Colors.green[800],
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
                                  _isEdit
                                      ? 'Simpan Perubahan'
                                      : 'Buat Pabrik',
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

  // ===========================================================================
  // FORM SUBMISSION
  // ===========================================================================

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // Panggil Provider
    final notifier = ref.read(factoryManagementProvider.notifier);

    try {
      if (_isEdit) {
        // --- LOGIKA UPDATE ---
        await notifier.updateFactory(
          id: widget.factoryToEdit!.id,
          factoryName: _factoryNameController.text.trim(),
          address: _addressController.text.trim(),
          noTelp: _noTelpController.text.trim(),
        );
        if (mounted) _showSuccess('Data pabrik berhasil diperbarui!');
      } else {
        // --- LOGIKA CREATE ---
        await notifier.createFactory(
          factoryName: _factoryNameController.text.trim(),
          address: _addressController.text.trim(),
          noTelp: _noTelpController.text.trim(),
        );
        if (mounted) _showSuccess('Pabrik baru berhasil dibuat!');
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
