import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/expedition_model.dart';
import '../../domain/expedition_provider.dart';

/// Screen untuk menambah expedisi baru (pencatatan pengiriman).
/// Merupakan full-screen terpisah yang dipanggil dari ManageExpeditionsScreen.
class AddExpeditionScreen extends ConsumerStatefulWidget {
  const AddExpeditionScreen({super.key});

  @override
  ConsumerState<AddExpeditionScreen> createState() =>
      _AddExpeditionScreenState();
}

class _AddExpeditionScreenState extends ConsumerState<AddExpeditionScreen> {
  final _formKey = GlobalKey<FormState>();

  final _destinationController = TextEditingController();
  final _sackNumberController = TextEditingController();

  String? _selectedDriverId;
  String? _selectedDriverName;
  DateTime _selectedDate = DateTime.now();
  File? _proofImage;

  // Auto-calculated total weight (sackNumber × weightPerSack)
  int _calculatedWeight = 0;

  @override
  void dispose() {
    _destinationController.dispose();
    _sackNumberController.dispose();
    super.dispose();
  }

  // ── Image picker ─────────────────────────────────────────────────────────

  Future<void> _pickImage({required bool fromCamera}) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80,
    );
    if (xFile != null) {
      setState(() => _proofImage = File(xFile.path));
    }
  }

  // ── Date picker ──────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // ── Submit ───────────────────────────────────────────────────────────────

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDriverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih driver terlebih dahulu.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih foto bukti pengiriman.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_calculatedWeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Total berat tidak valid. Periksa jumlah karung.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Tampilkan dialog konfirmasi
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Expedisi'),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfirmRow(
                'Tujuan', _destinationController.text.trim()),
            const SizedBox(height: 6),
            _buildConfirmRow('Driver', _selectedDriverName ?? '-'),
            const SizedBox(height: 6),
            _buildConfirmRow(
              'Tanggal',
              DateFormat('dd MMM yyyy').format(_selectedDate),
            ),
            const SizedBox(height: 6),
            _buildConfirmRow(
                'Jumlah Karung', _sackNumberController.text.trim()),
            const SizedBox(height: 6),
            _buildConfirmRow(
                'Total Berat', '$_calculatedWeight kg'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('BATAL',
                style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.white,
            ),
            child: const Text('SIMPAN'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Tampilkan loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final expeditionData = ExpeditionModel(
        id: '',
        idPartner: _selectedDriverId!,
        expeditionDate: _selectedDate,
        destination: _destinationController.text.trim(),
        sackNumber: int.tryParse(_sackNumberController.text.trim()) ?? 0,
        totalWeight: _calculatedWeight,
        proofOfDelivery: '',
      );

      await ref
          .read(manageExpeditionNotifierProvider.notifier)
          .createExpedition(expeditionData, _proofImage!);

      if (mounted) Navigator.of(context).pop(); // tutup loading

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expedisi berhasil disimpan!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(); // kembali ke hub
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // tutup loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(manageExpeditionNotifierProvider);
    final isLoading = actionState.isLoading;
    final weightAsync = ref.watch(weightPerSackProvider);
    final weightPerSack = weightAsync.value ?? 50;
    final stockAsync = ref.watch(availableStockProvider);
    final availableStock = stockAsync.value ?? double.infinity;
    final stockExceeded =
        _calculatedWeight > 0 && _calculatedWeight > availableStock;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Tambah Expedisi',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.grey[200],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.grey),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Tujuan ───────────────────────────────────────────
                      _buildSectionLabel('Tujuan Pengiriman'),
                      TextFormField(
                        controller: _destinationController,
                        decoration: _inputDecoration(
                          hint: 'Masukkan kota tujuan',
                          prefixIcon: Icons.location_on_outlined,
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty)
                                ? 'Tujuan tidak boleh kosong'
                                : null,
                      ),

                      const SizedBox(height: 16),

                      // ── Driver ───────────────────────────────────────────
                      _buildSectionLabel('Driver'),
                      _buildDriverDropdown(isLoading),

                      const SizedBox(height: 16),

                      // ── Tanggal ──────────────────────────────────────────
                      _buildSectionLabel('Tanggal Pengiriman'),
                      _buildDateField(),

                      const SizedBox(height: 16),

                      // ── Jumlah Karung ────────────────────────────────────
                      _buildSectionLabel('Jumlah Karung'),
                      TextFormField(
                        controller: _sackNumberController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _inputDecoration(
                          hint: 'contoh: 10',
                          prefixIcon: Icons.inventory_2_outlined,
                        ),
                        onChanged: (v) {
                          final sacks = int.tryParse(v) ?? 0;
                          setState(() {
                            _calculatedWeight = sacks * weightPerSack;
                          });
                        },
                        validator: (v) =>
                            (v == null || v.isEmpty)
                                ? 'Jumlah karung tidak boleh kosong'
                                : null,
                      ),

                      const SizedBox(height: 16),

                      // ── Total Berat (auto-calculated, read-only) ─────────
                      _buildSectionLabel('Total Berat (kg) — Otomatis'),
                      _buildCalculatedWeightField(weightPerSack),

                      const SizedBox(height: 8),

                      // ── Stok Tersedia Badge ──────────────────────────────
                      _buildStockBadge(stockAsync, stockExceeded),

                      const SizedBox(height: 16),

                      // ── Bukti Pengiriman ─────────────────────────────────
                      _buildSectionLabel('Bukti Pengiriman'),
                      _buildImageSection(isLoading),

                      const SizedBox(height: 32),

                      // ── Tombol Simpan ────────────────────────────────────
                      ElevatedButton.icon(
                        onPressed:
                            isLoading || stockExceeded ? null : _handleSubmit,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text(
                          'Simpan Expedisi',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: stockExceeded
                              ? AppColors.grey
                              : AppColors.secondary,
                          foregroundColor: AppColors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Tombol Batal ─────────────────────────────────────
                      OutlinedButton(
                        onPressed:
                            isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.grey),
                          foregroundColor: AppColors.greyDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Batal'),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ── Helper widgets ────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          const TextStyle(color: AppColors.grey, fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: AppColors.grey, size: 20),
      filled: true,
      fillColor: AppColors.greyLighter,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: AppColors.secondary, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  /// Dropdown driver yang memuat data langsung dari Supabase profiles
  Widget _buildDriverDropdown(bool isLoading) {
    final driversAsync = ref.watch(driverOptionsProvider);

    return driversAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.greyLighter,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.secondary),
            ),
            SizedBox(width: 10),
            Text('Memuat daftar driver...',
                style: TextStyle(color: AppColors.grey)),
          ],
        ),
      ),
      error: (e, _) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Text(
          'Gagal memuat driver: $e',
          style: const TextStyle(color: AppColors.error, fontSize: 13),
        ),
      ),
      data: (drivers) => DropdownButtonFormField<String>(
        value: _selectedDriverId,
        isExpanded: true,
        hint: const Text(
          'Pilih driver',
          style: TextStyle(color: AppColors.grey),
        ),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.person_outline,
              color: AppColors.grey, size: 20),
          filled: true,
          fillColor: AppColors.greyLighter,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
                color: AppColors.secondary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        items: drivers
            .map(
              (d) => DropdownMenuItem(
                value: d.id,
                child: Text(d.name, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: isLoading
            ? null
            : (value) {
                final driver =
                    drivers.firstWhere((d) => d.id == value);
                setState(() {
                  _selectedDriverId = value;
                  _selectedDriverName = driver.name;
                });
              },
        validator: (v) =>
            v == null ? 'Harap pilih driver' : null,
      ),
    );
  }

  /// Read-only field that shows auto-calculated total weight
  Widget _buildCalculatedWeightField(int weightPerSack) {
    final sacks = int.tryParse(_sackNumberController.text) ?? 0;
    final hasInput = sacks > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: hasInput
            ? AppColors.secondary.withValues(alpha: 0.06)
            : AppColors.greyLighter,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasInput
              ? AppColors.secondary.withValues(alpha: 0.4)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.scale,
              size: 20,
              color: hasInput ? AppColors.secondary : AppColors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: hasInput
                ? RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.black),
                      children: [
                        TextSpan(
                          text: '$_calculatedWeight kg',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                        TextSpan(
                          text:
                              '  ($sacks karung × $weightPerSack kg)',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.grey),
                        ),
                      ],
                    ),
                  )
                : const Text(
                    'Isi jumlah karung terlebih dahulu',
                    style: TextStyle(
                        color: AppColors.grey, fontSize: 14),
                  ),
          ),
          if (hasInput)
            const Icon(Icons.calculate_outlined,
                size: 16, color: AppColors.secondary),
        ],
      ),
    );
  }

  /// Badge showing current available warehouse stock.
  /// Green when sufficient, red with warning when exceeded.
  Widget _buildStockBadge(AsyncValue<double> stockAsync, bool stockExceeded) {
    return stockAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.greyLighter,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.grey),
            ),
            SizedBox(width: 8),
            Text('Memuat stok tersedia...',
                style: TextStyle(fontSize: 12, color: AppColors.grey)),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (available) {
        final color = stockExceeded ? AppColors.error : AppColors.success;
        final icon =
            stockExceeded ? Icons.warning_amber_rounded : Icons.check_circle_outline;
        final label = stockExceeded
            ? 'Stok tidak cukup! Tersedia: ${available.toStringAsFixed(0)} kg, '
              'dibutuhkan: $_calculatedWeight kg'
            : 'Stok tersedia: ${available.toStringAsFixed(0)} kg';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Field tanggal dengan InkWell + date picker
  Widget _buildDateField() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.greyLighter,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today,
                size: 20, color: AppColors.grey),
            const SizedBox(width: 12),
            Text(
              DateFormat('dd MMM yyyy').format(_selectedDate),
              style: const TextStyle(
                  fontSize: 14, color: AppColors.black),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: AppColors.grey),
          ],
        ),
      ),
    );
  }

  /// Section preview gambar + tombol kamera / galeri
  Widget _buildImageSection(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Preview gambar jika sudah dipilih
        if (_proofImage != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              _proofImage!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: isLoading
                ? null
                : () => setState(() => _proofImage = null),
            icon: const Icon(Icons.delete_outline,
                size: 16, color: AppColors.error),
            label: const Text(
              'Hapus Foto',
              style: TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],

        // Tombol Kamera & Galeri
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isLoading
                    ? null
                    : () => _pickImage(fromCamera: true),
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Kamera',
                    style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.secondary),
                  foregroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isLoading
                    ? null
                    : () => _pickImage(fromCamera: false),
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Galeri',
                    style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.secondary),
                  foregroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Baris ringkasan di dialog konfirmasi
  Widget _buildConfirmRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            '$label:',
            style: const TextStyle(
                color: AppColors.grey, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
