import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/api/supabase_client_api.dart';
import '../../../manage_factories/domain/providers/factory_provider.dart';
import '../../data/models/add_perca_plan_model.dart';
import '../../domain/providers/perca_plan_providers.dart';

class PercaPlanFormDialog extends ConsumerStatefulWidget {
  /// Jika null, berarti mode CREATE. Jika ada isi, berarti mode EDIT.
  final AddPercaPlanModel? planToEdit;

  const PercaPlanFormDialog({super.key, this.planToEdit});

  @override
  ConsumerState<PercaPlanFormDialog> createState() =>
      _PercaPlanFormDialogState();
}

class _PercaPlanFormDialogState extends ConsumerState<PercaPlanFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late DateTime _selectedDate;
  String? _selectedFactoryId;
  String? _selectedFactoryName;
  final _notesController = TextEditingController();

  bool get _isEdit => widget.planToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _selectedDate = widget.planToEdit!.plannedDate;
      _selectedFactoryId = widget.planToEdit!.idFactory;
      _notesController.text = widget.planToEdit!.notes ?? '';
    } else {
      _selectedDate = DateTime.now();
      _selectedFactoryId = null;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Format tanggal menjadi format Indonesia
  String _formatDate(DateTime date) {
    return DateFormat('d MMMM yyyy', 'id_ID').format(date);
  }

  /// Menampilkan date picker
  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Handle form submission
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFactoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih pabrik terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text('Memproses...')),
          ],
        ),
      ),
    );

    try {
      if (_isEdit) {
        // Update plan
        await ref.read(updatePlanProvider.notifier).updatePlan(
              widget.planToEdit!.id,
              plannedDate: _selectedDate,
              notes:
                  _notesController.text.isEmpty
                      ? null
                      : _notesController.text,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rencana berhasil diubah'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Create plan
        final userId = ref.read(currentUserProvider).value?.id;
        if (userId == null) {
          throw Exception('User tidak teridentifikasi');
        }

        await ref.read(createPlanProvider.notifier).createPlan(
              idFactory: _selectedFactoryId!,
              plannedDate: _selectedDate,
              createdBy: userId,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rencana berhasil dibuat'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        // Close loading dialog
        Navigator.pop(context);
        // Close form dialog
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final factoriesAsync = ref.watch(factoriesListProvider);
    final String title =
        _isEdit
            ? 'Ubah Rencana Pengambilan Perca'
            : 'Buat Rencana Pengambilan Perca';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: factoriesAsync.when(
          data: (factories) {
            // Get factory name for edit mode
            if (_isEdit && _selectedFactoryName == null) {
              try {
                final factory = factories.firstWhere(
                  (f) => f.id == _selectedFactoryId,
                );
                _selectedFactoryName = factory.factoryName;
              } catch (_) {
                _selectedFactoryName = 'Unknown Factory';
              }
            }

            return SingleChildScrollView(
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

                    // 1. Pilih Pabrik
                    _buildLabel('Pilih Pabrik'),
                    if (_isEdit)
                      // Read-only display for edit mode
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.factory,
                                color: Colors.grey.shade600),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedFactoryName ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Pabrik tidak dapat diubah',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      // Dropdown for create mode
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedFactoryId,
                          hint: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('Pilih pabrik...'),
                          ),
                          items: factories.map((factory) {
                            return DropdownMenuItem<String>(
                              value: factory.id,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      factory.factoryName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      factory.address,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              final factory = factories.firstWhere(
                                (f) => f.id == newValue,
                              );
                              setState(() {
                                _selectedFactoryId = newValue;
                                _selectedFactoryName =
                                    factory.factoryName;
                              });
                            }
                          },
                          underline: const SizedBox(),
                        ),
                      ),

                    // Selected factory info
                    if (_selectedFactoryId != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          border: Border.all(color: Colors.blue.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.blue.shade600),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Pabrik: $_selectedFactoryName',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // 2. Tanggal Rencana
                    const SizedBox(height: 16),
                    _buildLabel('Tanggal Rencana Pengambilan'),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _pickDate(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    color: Colors.blue),
                                const SizedBox(width: 12),
                                Text(
                                  _formatDate(_selectedDate),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 3. Catatan (Optional)
                    const SizedBox(height: 16),
                    _buildLabel('Catatan (Opsional)'),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Tambahkan catatan untuk rencana ini...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Batal',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              _isEdit ? 'Simpan Perubahan' : 'Buat Rencana',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $error',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build label widget
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
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
}

/// Provider untuk current user
final currentUserProvider = FutureProvider((ref) async {
  // Implement based on your auth setup
  final supabase = ref.watch(supabaseClientProvider);
  return supabase.auth.currentUser;
});
