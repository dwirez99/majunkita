import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/tailor_model.dart';
import '../../domain/providers/tailor_provider.dart';

/// Screen untuk form Add/Edit Tailor
class TailorFormScreen extends ConsumerStatefulWidget {
  final TailorModel? tailor; // Null jika create, ada value jika edit

  const TailorFormScreen({
    super.key,
    this.tailor,
  });

  @override
  ConsumerState<TailorFormScreen> createState() => _TailorFormScreenState();
}

class _TailorFormScreenState extends ConsumerState<TailorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _noTelpController = TextEditingController();
  final _alamatController = TextEditingController();
  final _spesialisasiController = TextEditingController();

  bool _isLoading = false;
  bool get _isEditMode => widget.tailor != null;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (_isEditMode) {
      final tailor = widget.tailor!;
      _namaController.text = tailor.namaLengkap;
      _emailController.text = tailor.email;
      _noTelpController.text = tailor.noTelp;
      _alamatController.text = tailor.alamat ?? '';
      _spesialisasiController.text = tailor.spesialisasi ?? '';
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _noTelpController.dispose();
    _alamatController.dispose();
    _spesialisasiController.dispose();
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
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  hintText: 'Masukkan nama lengkap penjahit',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama lengkap harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'contoh@email.com',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email harus diisi';
                  }
                  // Simple email validation
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Format email tidak valid';
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

              // Alamat (Optional)
              TextFormField(
                controller: _alamatController,
                decoration: const InputDecoration(
                  labelText: 'Alamat (Opsional)',
                  hintText: 'Masukkan alamat lengkap',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Spesialisasi (Optional)
              TextFormField(
                controller: _spesialisasiController,
                decoration: const InputDecoration(
                  labelText: 'Spesialisasi (Opsional)',
                  hintText: 'Contoh: Jahit Baju, Tas, Aksesoris',
                  prefixIcon: Icon(Icons.work),
                  border: OutlineInputBorder(),
                ),
              ),
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
                child: _isLoading
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

      if (_isEditMode) {
        // Update existing tailor
        await notifier.updateTailor(
          id: widget.tailor!.id,
          namaLengkap: _namaController.text.trim(),
          email: _emailController.text.trim(),
          noTelp: _noTelpController.text.trim(),
          alamat: _alamatController.text.trim().isEmpty
              ? null
              : _alamatController.text.trim(),
          spesialisasi: _spesialisasiController.text.trim().isEmpty
              ? null
              : _spesialisasiController.text.trim(),
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
          namaLengkap: _namaController.text.trim(),
          email: _emailController.text.trim(),
          noTelp: _noTelpController.text.trim(),
          alamat: _alamatController.text.trim().isEmpty
              ? null
              : _alamatController.text.trim(),
          spesialisasi: _spesialisasiController.text.trim().isEmpty
              ? null
              : _spesialisasiController.text.trim(),
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
