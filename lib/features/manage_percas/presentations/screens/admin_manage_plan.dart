import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/add_perca_plan_model.dart';
import '../../../manage_percas/domain/providers/perca_plan_providers.dart';
import 'widgets/perca_plan_card_widget.dart';
import 'perca_plan_form_dialog.dart';

class AdminManagePlan extends ConsumerStatefulWidget {
  const AdminManagePlan({super.key});

  @override
  ConsumerState<AdminManagePlan> createState() => _AdminManagePlanState();
}

class _AdminManagePlanState extends ConsumerState<AdminManagePlan> {
  String _selectedStatus = 'ALL';
  bool _sortAscending = false;
  final int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    final plansState = ref.watch(allPlansProvider(_currentPage));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rencana Pengambilan Perca'),
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: Column(
        children: [
          // === BUTTON TAMBAH RENCANA ===
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () => _showCreatePlanDialog(context),
                icon: const Icon(Icons.add_circle, size: 24),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[400],
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                label: const Text(
                  'Tambah Rencana Pengambilan Perca',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          // === FILTER SECTION ===
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Status:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusFilterChip('ALL', 'Semua'),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip('PENDING', 'Menunggu'),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip('APPROVED', 'Disetujui'),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip('REJECTED', 'Ditolak'),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip('COMPLETED', 'Selesai'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // === SORT SECTION ===
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Urutan Tanggal:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    _buildSortButton('Naik', !_sortAscending),
                    const SizedBox(width: 8),
                    _buildSortButton('Turun', _sortAscending),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // === LIST VIEW ===
          Expanded(
            child: plansState.when(
              data: (plans) {
                // Filter plans berdasarkan status
                List<AddPercaPlanModel> filteredPlans = plans;
                if (_selectedStatus != 'ALL') {
                  filteredPlans = plans
                      .where((plan) => plan.status == _selectedStatus)
                      .toList();
                }

                // Sort plans berdasarkan ascending/descending
                filteredPlans.sort((a, b) {
                  int comparison = a.plannedDate.compareTo(b.plannedDate);
                  return _sortAscending ? comparison : -comparison;
                });

                if (filteredPlans.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada rencana',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredPlans.length,
                  itemBuilder: (context, index) {
                    final plan = filteredPlans[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: PercaPlanCardWidget(
                        plan: plan,
                        onDelete: () {
                          ref.invalidate(allPlansProvider);
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: $error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build status filter chip
  Widget _buildStatusFilterChip(String value, String label) {
    final isSelected = _selectedStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = value;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.blue.shade200,
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue.shade700 : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  /// Build sort button
  Widget _buildSortButton(String label, bool isSelected) {
    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          _sortAscending = !_sortAscending;
        });
      },
      icon: Icon(
        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
        size: 16,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue.shade400 : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.grey[700],
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      label: Text(label),
    );
  }

  /// Show create plan dialog
  void _showCreatePlanDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PercaPlanFormDialog(),
    );
  }
}