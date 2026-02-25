import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../data/models/expedition_model.dart';
import '../../domain/expedition_provider.dart';

/// Screen utama untuk mengelola expedisi (Manage Expeditions)
class ManageExpeditionsScreen extends ConsumerStatefulWidget {
  const ManageExpeditionsScreen({super.key});

  @override
  ConsumerState<ManageExpeditionsScreen> createState() =>
      _ManageExpeditionsScreenState();
}

class _ManageExpeditionsScreenState
    extends ConsumerState<ManageExpeditionsScreen> {
  @override
  Widget build(BuildContext context) {
    // Pantau state dari provider expedisi untuk mengetahui loading/error
    final expeditionsAsync = ref.watch(expeditionListProvider);
    final actionState = ref.watch(manageExpeditionNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Manage Expeditions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.grey[200],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // Tombol refresh untuk memuat ulang daftar expedisi
          IconButton(
            onPressed: () => ref.invalidate(expeditionListProvider),
            icon: const Icon(Icons.refresh, color: Colors.black),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: SafeArea(
        child: expeditionsAsync.when(
          // Tampilkan daftar expedisi jika data berhasil dimuat
          data: (expeditions) {
            if (expeditions.isEmpty) {
              // Tampilkan pesan kosong jika belum ada data
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No expeditions yet.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            // Tampilkan ListView dengan kartu untuk setiap expedisi
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: expeditions.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final expedition = expeditions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildExpeditionCard(context, expedition),
                );
              },
            );
          },
          // Tampilkan loading indicator saat data sedang dimuat
          loading: () => const Center(child: CircularProgressIndicator()),
          // Tampilkan pesan error jika gagal memuat data
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Failed to load: $error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(expeditionListProvider),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
      // FAB untuk membuka form tambah expedisi
      floatingActionButton: FloatingActionButton.extended(
        // Nonaktifkan tombol jika ada operasi yang sedang berjalan
        onPressed: actionState.isLoading
            ? null
            : () => _showAddExpeditionBottomSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Expedition'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
    );
  }

  /// Widget kartu untuk menampilkan detail satu expedisi
  Widget _buildExpeditionCard(BuildContext context, ExpeditionModel expedition) {
    // Format tanggal ke format yang mudah dibaca
    final dateFormatted =
        DateFormat('dd MMM yyyy').format(expedition.expeditionDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris atas: judul destination dan tombol hapus
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  expedition.destination,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              // Tombol delete untuk menghapus expedisi
              IconButton(
                onPressed: () =>
                    _showDeleteConfirmation(context, expedition),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                ),
                tooltip: 'Delete Expedition',
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Baris info: tanggal expedisi
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.grey, size: 16),
              const SizedBox(width: 6),
              Text(
                'Date: $dateFormatted',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Baris info: jumlah karung dan berat total
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined,
                  color: Colors.grey, size: 16),
              const SizedBox(width: 6),
              Text(
                'Sacks: ${expedition.sackNumber}  |  Weight: ${expedition.totalWeight} kg',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Baris info: nama partner (jika tersedia dari JOIN)
          if (expedition.partnerName != null) ...[
            Row(
              children: [
                const Icon(Icons.person_outline, color: Colors.grey, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Partner: ${expedition.partnerName}',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],

          // Tampilkan thumbnail bukti pengiriman jika URL tersedia
          if (expedition.proofOfDelivery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.image_outlined, color: Colors.grey, size: 16),
                const SizedBox(width: 6),
                const Text(
                  'Proof of Delivery:',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(width: 8),
                // Thumbnail kecil bukti pengiriman
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    expedition.proofOfDelivery,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image,
                            size: 24, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Tampilkan bottom sheet untuk menambah expedisi baru
  void _showAddExpeditionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _AddExpeditionForm(),
    );
  }

  /// Tampilkan dialog konfirmasi sebelum menghapus expedisi
  void _showDeleteConfirmation(
      BuildContext context, ExpeditionModel expedition) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expedition'),
        content: Text(
          'Are you sure you want to delete the expedition to "${expedition.destination}"?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog konfirmasi

              try {
                // Panggil notifier untuk hapus expedisi
                await ref
                    .read(manageExpeditionNotifierProvider.notifier)
                    .deleteExpedition(
                      expedition.id,
                      expedition.proofOfDelivery,
                    );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Expedition deleted successfully.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// FORM WIDGET (Bottom Sheet)
// ===========================================================================

/// Form untuk menambahkan expedisi baru (ditampilkan sebagai BottomSheet)
class _AddExpeditionForm extends ConsumerStatefulWidget {
  const _AddExpeditionForm();

  @override
  ConsumerState<_AddExpeditionForm> createState() => _AddExpeditionFormState();
}

class _AddExpeditionFormState extends ConsumerState<_AddExpeditionForm> {
  final _formKey = GlobalKey<FormState>();

  // Controller untuk setiap input field pada form
  final _destinationController = TextEditingController();
  final _sackNumberController = TextEditingController();
  final _totalWeightController = TextEditingController();
  final _partnerIdController = TextEditingController();

  File? _proofImage; // File gambar bukti pengiriman yang dipilih
  DateTime _selectedDate = DateTime.now(); // Tanggal expedisi yang dipilih

  @override
  void dispose() {
    // Bersihkan semua controller saat widget dihapus dari tree
    _destinationController.dispose();
    _sackNumberController.dispose();
    _totalWeightController.dispose();
    _partnerIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pantau state loading dari notifier
    final actionState = ref.watch(manageExpeditionNotifierProvider);
    final isLoading = actionState.isLoading;

    return Padding(
      // Sesuaikan padding dengan keyboard agar form tidak tertutup
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Garis indikator di bagian atas bottom sheet
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Judul form
              const Center(
                child: Text(
                  'Add New Expedition',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Input: Destination
              _buildLabel('Destination'),
              _buildTextField(
                controller: _destinationController,
                hint: 'Enter destination city',
                validator: (v) =>
                    v!.isEmpty ? 'Destination is required' : null,
              ),

              // Input: Partner ID (placeholder TextField)
              _buildLabel('Partner ID'),
              _buildTextField(
                controller: _partnerIdController,
                hint: 'Enter partner UUID',
                validator: (v) => v!.isEmpty ? 'Partner ID is required' : null,
              ),

              // Input: Sack Number (numerik)
              _buildLabel('Sack Number'),
              _buildTextField(
                controller: _sackNumberController,
                hint: 'e.g. 10',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) =>
                    v!.isEmpty ? 'Sack number is required' : null,
              ),

              // Input: Total Weight (numerik)
              _buildLabel('Total Weight (kg)'),
              _buildTextField(
                controller: _totalWeightController,
                hint: 'e.g. 150',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) =>
                    v!.isEmpty ? 'Total weight is required' : null,
              ),

              // Input: Expedition Date (Date Picker)
              _buildLabel('Expedition Date'),
              _buildDatePicker(context),
              const SizedBox(height: 16),

              // Input: Proof of Delivery (Image Picker)
              _buildLabel('Proof of Delivery'),
              _buildImagePicker(isLoading),
              const SizedBox(height: 32),

              // Tombol aksi: Batal dan Simpan
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed:
                          isLoading ? null : () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      // Tampilkan loading spinner saat sedang menyimpan
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Save',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // HELPER WIDGETS
  // ===========================================================================

  /// Widget label untuk setiap field form
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 12.0),
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

  /// Widget TextField yang konsisten dengan style keseluruhan form
  Widget _buildTextField({
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
    );
  }

  /// Widget untuk memilih tanggal expedisi
  Widget _buildDatePicker(BuildContext context) {
    final dateFormatted =
        DateFormat('dd MMM yyyy').format(_selectedDate);

    return InkWell(
      onTap: () async {
        // Buka dialog pemilih tanggal
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
            const SizedBox(width: 10),
            Text(
              dateFormatted,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget untuk memilih gambar bukti pengiriman
  Widget _buildImagePicker(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tampilkan preview gambar jika sudah dipilih
        if (_proofImage != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              _proofImage!,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Tombol untuk memilih gambar dari kamera atau galeri
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isLoading
                    ? null
                    : () => _pickImage(fromCamera: true),
                icon: const Icon(Icons.camera_alt, size: 18),
                label:
                    const Text('Camera', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: BorderSide(color: Colors.blue[700]!),
                  foregroundColor: Colors.blue[700],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isLoading
                    ? null
                    : () => _pickImage(fromCamera: false),
                icon: const Icon(Icons.photo_library, size: 18),
                label:
                    const Text('Gallery', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: BorderSide(color: Colors.blue[700]!),
                  foregroundColor: Colors.blue[700],
                ),
              ),
            ),
          ],
        ),

        // Tombol hapus gambar jika sudah dipilih
        if (_proofImage != null)
          TextButton.icon(
            onPressed: isLoading
                ? null
                : () => setState(() => _proofImage = null),
            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
            label: const Text(
              'Remove Image',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  // ===========================================================================
  // HANDLERS
  // ===========================================================================

  /// Memilih gambar dari kamera atau galeri menggunakan ImagePicker
  Future<void> _pickImage({required bool fromCamera}) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    );
    if (xFile != null) {
      setState(() => _proofImage = File(xFile.path));
    }
  }

  /// Menangani submit form: validasi, buat model, panggil notifier
  Future<void> _handleSubmit() async {
    // Validasi semua field wajib di form
    if (!_formKey.currentState!.validate()) return;

    // Pastikan gambar bukti pengiriman sudah dipilih
    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a proof of delivery image.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Buat model expedisi dari input form
      final expeditionData = ExpeditionModel(
        id: '', // ID akan digenerate oleh database (uuid_generate_v4)
        idPartner: _partnerIdController.text.trim(),
        expeditionDate: _selectedDate,
        destination: _destinationController.text.trim(),
        sackNumber: int.tryParse(_sackNumberController.text.trim()) ?? 0,
        totalWeight: int.tryParse(_totalWeightController.text.trim()) ?? 0,
        proofOfDelivery: '', // Akan diisi URL setelah upload berhasil
      );

      // Panggil notifier untuk create expedisi dan upload gambar
      await ref
          .read(manageExpeditionNotifierProvider.notifier)
          .createExpedition(expeditionData, _proofImage!);

      if (mounted) {
        // Tutup bottom sheet setelah berhasil
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expedition created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
