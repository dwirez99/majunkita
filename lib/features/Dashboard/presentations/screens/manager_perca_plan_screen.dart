import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../manage_percas/domain/providers/perca_plan_providers.dart';
import '../../../manage_percas/data/models/add_perca_plan_model.dart';
import '../widgets/dashboard_appbar.dart';

class ManagerPercaPlanScreen extends ConsumerStatefulWidget {
  const ManagerPercaPlanScreen({super.key});

  @override
  ConsumerState<ManagerPercaPlanScreen> createState() =>
      _ManagerPercaPlanScreenState();
}

class _ManagerPercaPlanScreenState extends ConsumerState<ManagerPercaPlanScreen> {
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    final pendingPlansState = ref.watch(pendingPlansProvider(_currentPage));
    final statsState = ref.watch(planStatsProvider);

    return Scaffold(
      appBar: DashboardAppBar(
        title: 'Rencana Pengambilan Perca',
        showBackButton: true,
      ),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(pendingPlansProvider);
          ref.invalidate(planStatsProvider);
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === STATISTICS CARDS ===
                statsState.when(
                  data: (stats) => _buildStatsRow(stats),
                  loading: () => const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 24),

                // === SECTION TITLE ===
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    'Rencana yang Menunggu Persetujuan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // === PENDING PLANS LIST ===
                pendingPlansState.when(
                  data: (plans) {
                    if (plans.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_available,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tidak ada rencana yang menunggu',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: plans.length,
                      itemBuilder: (context, index) {
                        final plan = plans[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: PercaPlanCardManager(
                            plan: plan,
                            onApprove: () => _showApproveConfirmation(context, plan),
                            onReject: () =>
                                _showRejectDialog(context, plan.id),
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
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              ref.invalidate(pendingPlansProvider),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // === PAGINATION ===
                _buildPaginationControls(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(Map<String, int> stats) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard('MENUNGGU', stats['PENDING'] ?? 0, Colors.orange),
          const SizedBox(width: 12),
          _buildStatCard('DISETUJUI', stats['APPROVED'] ?? 0, Colors.green),
          const SizedBox(width: 12),
          _buildStatCard('DITOLAK', stats['REJECTED'] ?? 0, Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: _currentPage > 1
              ? () {
                  setState(() => _currentPage--);
                  ref.invalidate(pendingPlansProvider);
                }
              : null,
          child: const Text('Sebelumnya'),
        ),
        const SizedBox(width: 16),
        Text('Halaman $_currentPage'),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () {
            setState(() => _currentPage++);
            ref.invalidate(pendingPlansProvider);
          },
          child: const Text('Berikutnya'),
        ),
      ],
    );
  }

  void _showApproveConfirmation(
      BuildContext context, AddPercaPlanModel plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setujui Rencana'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apakah Anda yakin ingin menyetujui rencana ini?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ID Pabrik: ${plan.idFactory}'),
                  const SizedBox(height: 4),
                  Text(
                    'Tanggal: ${plan.plannedDate.day}/${plan.plannedDate.month}/${plan.plannedDate.year}',
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            onPressed: () {
              ref.read(approvePlanProvider.notifier).approvePlan(plan.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rencana berhasil disetujui')),
              );
              ref.invalidate(pendingPlansProvider);
              ref.invalidate(planStatsProvider);
            },
            child: const Text('Setujui'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, String planId) {
    showDialog(
      context: context,
      builder: (context) => _RejectPlanDialog(
        planId: planId,
        onSubmit: (reason) {
          ref
              .read(rejectPlanProvider.notifier)
              .rejectPlan(planId, reason);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rencana berhasil ditolak')),
          );
          ref.invalidate(pendingPlansProvider);
          ref.invalidate(planStatsProvider);
        },
      ),
    );
  }
}

// ============================================================================
// PERCA PLAN CARD FOR MANAGER
// ============================================================================

class PercaPlanCardManager extends StatelessWidget {
  final AddPercaPlanModel plan;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const PercaPlanCardManager({
    super.key,
    required this.plan,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: Colors.orange,
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === HEADER ===
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'MENUNGGU PERSETUJUAN',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pabrik ID: ${plan.idFactory}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // === DETAILS ===
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      'Tanggal Rencana',
                      '${plan.plannedDate.day}/${plan.plannedDate.month}/${plan.plannedDate.year}',
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Dibuat Oleh',
                      plan.createdBy,
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Dibuat Pada',
                      '${plan.createdAt.hour}:${plan.createdAt.minute.toString().padLeft(2, '0')} - ${plan.createdAt.day}/${plan.createdAt.month}/${plan.createdAt.year}',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // === ACTION BUTTONS ===
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Setujui'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.cancel),
                      label: const Text('Tolak'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ============================================================================
// REJECT PLAN DIALOG
// ============================================================================

class _RejectPlanDialog extends StatefulWidget {
  final String planId;
  final Function(String reason) onSubmit;

  const _RejectPlanDialog({
    required this.planId,
    required this.onSubmit,
  });

  @override
  State<_RejectPlanDialog> createState() => _RejectPlanDialogState();
}

class _RejectPlanDialogState extends State<_RejectPlanDialog> {
  late TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tolak Rencana'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Silakan berikan alasan penolakan:',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Masukkan alasan penolakan...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _reasonController.text.isNotEmpty
              ? () {
                  widget.onSubmit(_reasonController.text);
                }
              : null,
          child: const Text('Tolak'),
        ),
      ],
    );
  }
}
