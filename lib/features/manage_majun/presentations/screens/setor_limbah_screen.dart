import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/providers/majun_provider.dart';

/// Screen untuk form setor limbah (pengembalian sisa/limbah dari penjahit)
/// TIDAK ADA UPAH — hanya mengurangi total_stock penjahit.
class SetorLimbahScreen extends ConsumerStatefulWidget {
  const SetorLimbahScreen({super.key});

  @override
  ConsumerState<SetorLimbahScreen> createState() => _SetorLimbahScreenState();
}

class _SetorLimbahScreenState extends ConsumerState<SetorLimbahScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();

  String? _selectedTailorId;
  String? _selectedTailorName;
  bool _isSubmitting = false;

  bool get _isFormValid {
    final weight = double.tryParse(_weightController.text) ?? 0;
    return _selectedTailorId != null && weight > 0;
  }

  Future<void> _submitSetorLimbah() async {
    if (!_formKey.currentState!.validate() || !_isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap lengkapi semua data'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Konfirmasi Setor Limbah'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildConfirmRow('Penjahit', _selectedTailorName ?? '-'),
                const SizedBox(height: 8),
                _buildConfirmRow(
                  'Berat Limbah',
                  '${_weightController.text} KG',
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange[700],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Setor limbah TIDAK menambah upah penjahit.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ),
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
                  backgroundColor: Colors.orange[700],
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

      final notifier = ref.read(setorLimbahNotifierProvider.notifier);
      final result = await notifier.setorLimbah(
        tailorId: _selectedTailorId!,
        weightLimbah: double.parse(_weightController.text),
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
                    Icon(
                      Icons.check_circle,
                      color: Colors.orange[600],
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Setor Limbah Berhasil!',
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
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Column(
                        children: [
                          _buildResultRow(
                            'Berat Limbah',
                            '${result.weightLimbah.toStringAsFixed(1)} KG',
                          ),
                          const Divider(),
                          _buildResultRow('Upah', 'Tidak ada (limbah)'),
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
                      backgroundColor: Colors.orange[700],
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
              onPressed: _submitSetorLimbah,
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
          Text(label, style: TextStyle(color: Colors.orange[800])),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange[900],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tailorListState = ref.watch(tailorListForMajunProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setor Limbah'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
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
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Catat limbah/sisa yang dikembalikan oleh penjahit. Setor limbah TIDAK menambah upah.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.orange[800],
                                ),
                              ),
                            ),
                          ],
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

                      // ── Input Berat Limbah ──
                      const Text(
                        'Berat Limbah (KG)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _weightController,
                        decoration: InputDecoration(
                          hintText: 'Masukkan berat limbah dalam KG',
                          prefixIcon: const Icon(Icons.delete_outline),
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
                      const SizedBox(height: 30),

                      // ── Tombol Submit ──
                      ElevatedButton.icon(
                        onPressed: _isFormValid ? _submitSetorLimbah : null,
                        icon: const Icon(Icons.send),
                        label: const Text('SETOR LIMBAH'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
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
                                _buildHintItem('Isi berat limbah (> 0)'),
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
