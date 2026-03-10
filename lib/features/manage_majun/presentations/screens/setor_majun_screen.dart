import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/providers/majun_provider.dart';

/// Screen untuk form setor majun (pencatatan hasil jahitan)
class SetorMajunScreen extends ConsumerStatefulWidget {
  const SetorMajunScreen({super.key});

  @override
  ConsumerState<SetorMajunScreen> createState() => _SetorMajunScreenState();
}

class _SetorMajunScreenState extends ConsumerState<SetorMajunScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  String? _selectedTailorId;
  String? _selectedTailorName;
  File? _capturedPhoto;
  bool _isSubmitting = false;

  double _estimatedWage = 0;
  double _pricePerKg = 0;

  @override
  void initState() {
    super.initState();
    _weightController.addListener(_calculateEstimate);
  }

  void _calculateEstimate() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    setState(() => _estimatedWage = weight * _pricePerKg);
  }

  Future<void> _capturePhoto() async {
    final ImagePicker picker = ImagePicker();
    // Show source selection dialog
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pilih Sumber Gambar'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(ctx).pop(ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Kamera'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.of(ctx).pop(ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('Galeri'),
          ),
        ],
      ),
    );
    if (source == null) return;
    while (true) {
      final XFile? imageXFile = await picker.pickImage(source: source);
      if (imageXFile == null) return;
      final File imageFile = File(imageXFile.path);
      if (!mounted) return;
      final bool? shouldUse = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _PhotoPreviewDialog(imageFile: imageFile),
      );
      if (shouldUse == true) {
        setState(() => _capturedPhoto = imageFile);
        break;
      } else if (shouldUse == false) {
        continue;
      } else {
        break;
      }
    }
  }

  bool get _isFormValid {
    final weight = double.tryParse(_weightController.text) ?? 0;
    return _selectedTailorId != null && weight > 0 && _capturedPhoto != null;
  }

  Future<void> _submitSetorMajun() async {
    if (!_formKey.currentState!.validate() || !_isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap lengkapi semua data termasuk foto bukti'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Konfirmasi Setor Majun'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildConfirmRow('Penjahit', _selectedTailorName ?? '-'),
                const SizedBox(height: 8),
                _buildConfirmRow('Berat Majun', '${_weightController.text} KG'),
                const SizedBox(height: 8),
                _buildConfirmRow(
                  'Estimasi Upah',
                  _currencyFormat.format(_estimatedWage),
                ),
                const SizedBox(height: 8),
                _buildConfirmRow(
                  'Harga/KG',
                  _currencyFormat.format(_pricePerKg),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('BATAL'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('KONFIRMASI'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(child: CircularProgressIndicator()),
        );
      }

      final notifier = ref.read(setorMajunNotifierProvider.notifier);
      final result = await notifier.setorMajun(
        tailorId: _selectedTailorId!,
        weightMajun: double.parse(_weightController.text),
        photo: _capturedPhoto!,
      );

      if (mounted) Navigator.of(context).pop(); // Tutup loading

      if (mounted) {
        await showDialog(
          context: context,
          builder:
              (ctx) => AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Setor Majun Berhasil!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Column(
                        children: [
                          _buildResultRow(
                            'Berat Majun',
                            '${result.weightMajun.toStringAsFixed(1)} KG',
                          ),
                          const Divider(),
                          _buildResultRow(
                            'Upah',
                            _currencyFormat.format(result.earnedWage),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'COBA LAGI',
              textColor: Colors.white,
              onPressed: _submitSetorMajun,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildConfirmRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.greyDark)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.green[800])),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green[900],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _weightController.removeListener(_calculateEstimate);
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tailorListState = ref.watch(tailorListForMajunProvider);
    final priceState = ref.watch(majunPricePerKgProvider);

    priceState.whenData((price) {
      if (_pricePerKg != price) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _pricePerKg = price);
            _calculateEstimate();
          }
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setor Majun'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat Ulang Data',
            onPressed: () {
              ref.invalidate(tailorListForMajunProvider);
              ref.invalidate(majunPricePerKgProvider);
            },
          ),
        ],
      ),
      body:
          _isSubmitting
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Header Info ──
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Catat hasil jahitan (lap majun) yang disetor oleh penjahit. Upah dihitung otomatis.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Harga Per KG Info ──
                      priceState.when(
                        data:
                            (price) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.monetization_on,
                                    color: Colors.amber[800],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Harga standar: ${_currencyFormat.format(price)} / KG',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.amber[900],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        loading: () => const LinearProgressIndicator(),
                        error:
                            (err, _) => Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Error mengambil harga: $err',
                                style: TextStyle(color: Colors.red[800]),
                              ),
                            ),
                      ),
                      const SizedBox(height: 20),

                      // ── Pilih Penjahit ──
                      const Text(
                        'Penjahit',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      tailorListState.when(
                        data: (tailorList) {
                          return DropdownButtonFormField<String>(
                            value: _selectedTailorId,
                            hint: const Text('Pilih Penjahit'),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items:
                                tailorList.map<DropdownMenuItem<String>>((
                                  tailor,
                                ) {
                                  return DropdownMenuItem<String>(
                                    value: tailor.id,
                                    child: Text(tailor.name),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              final selected = tailorList.firstWhere(
                                (t) => t.id == value,
                              );
                              setState(() {
                                _selectedTailorId = value;
                                _selectedTailorName = selected.name;
                              });
                            },
                            validator:
                                (value) =>
                                    value == null
                                        ? 'Penjahit wajib dipilih'
                                        : null,
                          );
                        },
                        loading:
                            () => _buildLoadingField('Loading penjahit...'),
                        error: (err, _) => _buildErrorField('Error: $err'),
                      ),
                      const SizedBox(height: 16),

                      // ── Input Berat Majun ──
                      const Text(
                        'Berat Majun (KG)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _weightController,
                        decoration: InputDecoration(
                          hintText: 'Masukkan berat lap majun dalam KG',
                          prefixIcon: const Icon(Icons.scale),
                          suffixText: 'KG',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Berat wajib diisi';
                          }
                          final weight = double.tryParse(value);
                          if (weight == null || weight <= 0) {
                            return 'Masukkan angka yang valid (> 0)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── Estimasi Upah (auto-calculate) ──
                      if (_estimatedWage > 0)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calculate,
                                        color: Colors.green[700],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Estimasi Upah:',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    _currencyFormat.format(_estimatedWage),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '${_weightController.text} KG × ${_currencyFormat.format(_pricePerKg)}/KG',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),

                      // ── Foto Bukti Timbangan ──
                      const Text(
                        'Foto Bukti Timbangan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (_capturedPhoto != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              Image.file(
                                _capturedPhoto!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.6,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.refresh,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        onPressed: _capturePhoto,
                                        tooltip: 'Foto Ulang',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(
                                          alpha: 0.7,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        onPressed:
                                            () => setState(
                                              () => _capturedPhoto = null,
                                            ),
                                        tooltip: 'Hapus Foto',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green[600],
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Foto bukti terlampir',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        InkWell(
                          onTap: _capturePhoto,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey[400]!),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  size: 48,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap untuk ambil foto timbangan',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Gunakan kamera atau pilih dari galeri',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 30),

                      // ── Tombol Submit ──
                      ElevatedButton.icon(
                        onPressed: _isFormValid ? _submitSetorMajun : null,
                        icon: const Icon(Icons.send),
                        label: const Text('SETOR MAJUN'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          disabledForegroundColor: Colors.grey[500],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Validation hints ──
                      if (!_isFormValid)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber,
                                    color: Colors.orange[700],
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Lengkapi data berikut:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange[800],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_selectedTailorId == null)
                                _buildHintItem('Pilih penjahit'),
                              if ((_weightController.text.isEmpty) ||
                                  (double.tryParse(_weightController.text) ??
                                          0) <=
                                      0)
                                _buildHintItem('Isi berat lap majun (> 0)'),
                              if (_capturedPhoto == null)
                                _buildHintItem('Ambil foto bukti timbangan'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildHintItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 4),
      child: Row(
        children: [
          Icon(Icons.circle, size: 6, color: Colors.orange[600]),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 12, color: Colors.orange[700])),
        ],
      ),
    );
  }

  Widget _buildLoadingField(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey[50],
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildErrorField(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red[200]!),
        borderRadius: BorderRadius.circular(10),
        color: Colors.red[50],
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPreviewDialog extends StatelessWidget {
  final File imageFile;
  const _PhotoPreviewDialog({required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pratinjau Foto Timbangan'),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      content: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(imageFile),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('FOTO ULANG'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.white,
          ),
          child: const Text('GUNAKAN FOTO INI'),
        ),
      ],
    );
  }
}
