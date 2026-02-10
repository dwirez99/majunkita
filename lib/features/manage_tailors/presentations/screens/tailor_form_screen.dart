import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/tailor_model.dart';
import '../../domain/providers/tailor_provider.dart';
import '../../../../core/services/storage_service_provider.dart';

/// Screen untuk form Add/Edit Tailor
class TailorFormScreen extends ConsumerStatefulWidget {
  final TailorModel? tailor; // Null jika create, ada value jika edit

  const TailorFormScreen({super.key, this.tailor});

  @override
  ConsumerState<TailorFormScreen> createState() => _TailorFormScreenState();
}

class _TailorFormScreenState extends ConsumerState<TailorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _noTelpController = TextEditingController();
  final _addressController = TextEditingController();
  final _tailorImagesController = TextEditingController();

  bool _isLoading = false;
  bool get _isEditMode => widget.tailor != null;
  File? _capturedImage; // Store captured image

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (_isEditMode) {
      final tailor = widget.tailor!;
      _nameController.text = tailor.name;
      _noTelpController.text = tailor.noTelp;
      _addressController.text = tailor.address;
      _tailorImagesController.text = tailor.tailorImages ?? '';
    }
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Penjahit' : 'Tambah Penjahit'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nama Lengkap
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Penjahit',
                  hintText: 'Masukkan nama penjahit',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama penjahit harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // No Telepon
              TextFormField(
                controller: _noTelpController,
                decoration: const InputDecoration(
                  labelText: 'No. Telepon',
                  hintText: '08xxxxxxxxxx',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'No. telepon harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Alamat
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  hintText: 'Masukkan alamat lengkap penjahit',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Alamat harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tailor Images (Camera Capture)
              _buildImageSection(),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Text(
                          _isEditMode ? 'Update Data' : 'Simpan Data',
                          style: const TextStyle(fontSize: 16),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // IMAGE SECTION UI
  // ===========================================================================

  Widget _buildImageSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.camera_alt, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Foto Profil Penjahit',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Ambil foto profil penjahit (opsional)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),

          // Preview image if available
          if (_capturedImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _capturedImage!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
          ] else if (_isEditMode && widget.tailor?.tailorImages != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.tailor!.tailorImages!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 50,
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
                      _isLoading ? null : () => _pickImage(fromCamera: true),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Kamera'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Gallery button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _isLoading ? null : () => _pickImage(fromCamera: false),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galeri'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),

          // Show remove button if image exists
          if (_capturedImage != null ||
              (_isEditMode && widget.tailor?.tailorImages != null))
            TextButton.icon(
              onPressed: _isLoading ? null : _removeImage,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text(
                'Hapus Foto',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // IMAGE HANDLING METHODS
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
      if (_isEditMode) {
        // Mark that we want to remove the existing image
        _tailorImagesController.text = '';
      }
    });
  }

  // ===========================================================================
  // FORM SUBMISSION
  // ===========================================================================

  void _submitForm() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final notifier = ref.read(tailorManagementProvider.notifier);
      String? finalImageUrl;

      // Handle image upload if there's a captured image
      if (_capturedImage != null) {
        // Upload image to Supabase Storage
        final storageService = ref.read(storageServiceProvider);

        // For new tailor, we need to create a temporary ID
        // For existing tailor, use the existing ID
        final tempId =
            _isEditMode
                ? widget.tailor!.id
                : 'temp-${DateTime.now().millisecondsSinceEpoch}';

        try {
          finalImageUrl = await storageService.uploadTailorImage(
            imageFile: _capturedImage!,
            tailorId: tempId,
          );
        } catch (e) {
          // If upload fails, show error and stop submission
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal mengupload gambar: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      } else if (_isEditMode) {
        // If editing and no new image, keep the existing image URL
        finalImageUrl = widget.tailor!.tailorImages;
      }

      if (_isEditMode) {
        // Update existing tailor
        await notifier.updateTailor(
          id: widget.tailor!.id,
          name: _nameController.text.trim(),
          noTelp: _noTelpController.text.trim(),
          address: _addressController.text.trim(),
          tailorImages: finalImageUrl,
          oldImageUrl: widget.tailor!.tailorImages, // Pass old image URL
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data penjahit berhasil diupdate'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        // Create new tailor
        await notifier.createTailor(
          name: _nameController.text.trim(),
          noTelp: _noTelpController.text.trim(),
          address: _addressController.text.trim(),
          tailorImages: finalImageUrl,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data penjahit berhasil ditambahkan'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show user-friendly error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getUserFriendlyErrorMessage(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Convert technical error to user-friendly message
  String _getUserFriendlyErrorMessage(String error) {
    if (error.contains('Email sudah')) {
      return error; // Already user-friendly from repository
    }
    if (error.contains('network') || error.contains('connection')) {
      return 'Koneksi internet bermasalah. Periksa koneksi Anda.';
    }
    if (error.contains('timeout')) {
      return 'Permintaan timeout. Coba lagi.';
    }
    return 'Terjadi kesalahan: $error';
  }
}
