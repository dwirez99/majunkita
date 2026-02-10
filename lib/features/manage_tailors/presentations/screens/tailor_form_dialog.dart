import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/tailor_model.dart';
import '../../domain/providers/tailor_provider.dart';
import '../../../../core/services/storage_service_provider.dart';

class TailorFormDialog extends ConsumerStatefulWidget {
  /// Jika null, berarti mode CREATE. Jika ada isi, berarti mode EDIT.
  final TailorModel? tailorToEdit;

  const TailorFormDialog({super.key, this.tailorToEdit});

  @override
  ConsumerState<TailorFormDialog> createState() => _TailorFormDialogState();
}

class _TailorFormDialogState extends ConsumerState<TailorFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _noTelpController;
  late TextEditingController _addressController;
  late TextEditingController _tailorImagesController;

  File? _capturedImage; // Store captured image
  bool get _isEdit => widget.tailorToEdit != null;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller dengan data jika mode Edit
    _nameController = TextEditingController(
      text: widget.tailorToEdit?.name ?? '',
    );
    _noTelpController = TextEditingController(
      text: widget.tailorToEdit?.noTelp ?? '',
    );
    _addressController = TextEditingController(
      text: widget.tailorToEdit?.address ?? '',
    );
    _tailorImagesController = TextEditingController(
      text: widget.tailorToEdit?.tailorImages ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noTelpController.dispose();
    _addressController.dispose();
    _tailorImagesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String title =
        _isEdit ? 'Edit Data Penjahit' : 'Tambah Penjahit Baru';

    // Dengarkan state loading dari provider gabungan
    final asyncState = ref.watch(tailorManagementProvider);
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

                // Nama Penjahit
                _buildLabel('Nama Penjahit'),
                _buildTextField(
                  controller: _nameController,
                  hint: 'Masukkan nama penjahit',
                  validator: (v) => v!.isEmpty ? 'Nama wajib diisi' : null,
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

                // Alamat Domisili
                _buildLabel('Alamat Domisili'),
                _buildTextField(
                  controller: _addressController,
                  hint: 'Alamat lengkap penjahit...',
                  maxLines: 3,
                  validator: (v) => v!.isEmpty ? 'Alamat wajib diisi' : null,
                ),

                // Foto Profil Section
                const SizedBox(height: 16),
                _buildImageSection(),

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
                                      : 'Buat Penjahit',
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
  // IMAGE SECTION
  // ===========================================================================

  Widget _buildImageSection() {
    final asyncState = ref.watch(tailorManagementProvider);
    final isLoading = asyncState.isLoading;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.camera_alt, color: Colors.green[800], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Foto Profil (Opsional)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Preview image if available
          if (_capturedImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _capturedImage!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
          ] else if (_isEdit && widget.tailorToEdit?.tailorImages != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.tailorToEdit!.tailorImages!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Buttons: Camera and Gallery
          Row(
            children: [
              // Camera button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      isLoading ? null : () => _pickImage(fromCamera: true),
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Kamera', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(color: Colors.green[800]!),
                    foregroundColor: Colors.green[800],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Gallery button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      isLoading ? null : () => _pickImage(fromCamera: false),
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('Galeri', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(color: Colors.green[800]!),
                    foregroundColor: Colors.green[800],
                  ),
                ),
              ),
            ],
          ),

          // Remove button
          if (_capturedImage != null ||
              (_isEdit && widget.tailorToEdit?.tailorImages != null))
            TextButton.icon(
              onPressed: isLoading ? null : _removeImage,
              icon: const Icon(
                Icons.delete_outline,
                size: 16,
                color: Colors.red,
              ),
              label: const Text(
                'Hapus Foto',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // IMAGE HANDLING
  // ===========================================================================

  /// Pick image from camera or gallery
  void _pickImage({required bool fromCamera}) async {
    // Use ImagePicker directly for both camera and gallery
    final ImagePicker picker = ImagePicker();
    final XFile? imageXFile = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    );

    if (imageXFile != null) {
      setState(() {
        _capturedImage = File(imageXFile.path);
      });
    }
  }

  /// Remove captured or existing image
  void _removeImage() {
    setState(() {
      _capturedImage = null;
      if (_isEdit) {
        _tailorImagesController.text = '';
      }
    });
  }

  // ===========================================================================
  // FORM SUBMISSION
  // ===========================================================================

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // Panggil Provider
    final notifier = ref.read(tailorManagementProvider.notifier);

    try {
      String? finalImageUrl;

      // Handle image upload if there's a captured image
      if (_capturedImage != null) {
        final storageService = ref.read(storageServiceProvider);

        // For new tailor, use temporary ID
        // For existing tailor, use the existing ID
        final tempId =
            _isEdit
                ? widget.tailorToEdit!.id
                : 'temp-${DateTime.now().millisecondsSinceEpoch}';

        try {
          finalImageUrl = await storageService.uploadTailorImage(
            imageFile: _capturedImage!,
            tailorId: tempId,
          );
        } catch (e) {
          // If upload fails, show error and stop submission
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal mengupload gambar: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      } else if (_isEdit) {
        // If editing and no new image, keep the existing image URL
        finalImageUrl = widget.tailorToEdit!.tailorImages;
      }

      if (_isEdit) {
        // --- LOGIKA UPDATE ---
        await notifier.updateTailor(
          id: widget.tailorToEdit!.id,
          name: _nameController.text.trim(),
          noTelp: _noTelpController.text.trim(),
          address: _addressController.text.trim(),
          tailorImages: finalImageUrl,
          oldImageUrl: widget.tailorToEdit!.tailorImages, // Pass old image URL
        );
        if (mounted) _showSuccess('Data penjahit berhasil diperbarui!');
      } else {
        // --- LOGIKA CREATE ---
        await notifier.createTailor(
          name: _nameController.text.trim(),
          noTelp: _noTelpController.text.trim(),
          address: _addressController.text.trim(),
          tailorImages: finalImageUrl,
        );
        if (mounted) _showSuccess('Penjahit baru berhasil dibuat!');
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
