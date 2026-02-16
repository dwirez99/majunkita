import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/add_perca_plan_model.dart';
import '../../../domain/providers/perca_plan_providers.dart';
import '../../../../manage_factories/domain/providers/factory_provider.dart';
import '../../../../manage_factories/data/models/factory_model.dart';
import '../../../../../core/api/supabase_client_api.dart';
import '../add_perca_screen.dart';

/// Reusable widget untuk menampilkan Perca Plan Card dengan data factory dan user
/// Digunakan di berbagai screens yang menampilkan plan list
class PercaPlanCardWidget extends ConsumerWidget {
  final AddPercaPlanModel plan;
  final VoidCallback? onDelete;
  final bool showActions;

  const PercaPlanCardWidget({
    super.key,
    required this.plan,
    this.onDelete,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get factory data
    final factoriesState = ref.watch(factoriesListProvider);

    // Get user profile data
    final supabase = ref.watch(supabaseClientProvider);

    Color statusColor;
    Color statusBgColor;
    Color borderColor;
    String statusLabel;

    switch (plan.status) {
      case 'PENDING':
        statusColor = Colors.orange[800]!;
        statusBgColor = Colors.orange[100]!;
        borderColor = Colors.orange;
        statusLabel = 'MENUNGGU';
        break;
      case 'APPROVED':
        statusColor = Colors.green[800]!;
        statusBgColor = Colors.green[100]!;
        borderColor = Colors.green;
        statusLabel = 'DISETUJUI';
        break;
      case 'REJECTED':
        statusColor = Colors.red[800]!;
        statusBgColor = Colors.red[100]!;
        borderColor = Colors.red;
        statusLabel = 'DITOLAK';
        break;
      default:
        statusColor = Colors.grey[800]!;
        statusBgColor = Colors.grey[100]!;
        borderColor = Colors.grey;
        statusLabel = plan.status;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: statusBgColor.withValues(alpha: 0.3),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === STATUS BADGE + FACTORY NAME ===
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: factoriesState.when(
                      data: (factories) {
                        FactoryModel? factory;
                        try {
                          factory = factories.firstWhere(
                            (f) => f.id == plan.idFactory,
                          );
                        } catch (_) {
                          factory = null;
                        }
                        return Text(
                          factory?.factoryName ?? 'Unknown',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                      loading: () => const SizedBox(
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (err, stack) => Text(
                        'Error',
                        style: TextStyle(color: Colors.red[300]),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // === DETAILS ROW ===
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tanggal Rencana',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMMM yyyy', 'id_ID')
                              .format(plan.plannedDate),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dibuat Oleh',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FutureBuilder<Map<String, dynamic>>(
                          future: _getUserProfile(supabase, plan.createdBy),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox(
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              );
                            }
                            if (snapshot.hasData && snapshot.data != null) {
                              final username = snapshot.data!['username'] ??
                                  snapshot.data!['name'] ??
                                  'Unknown';
                              return Text(
                                username,
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            }
                            return Text(
                              plan.createdBy.substring(0, 8),
                              style: const TextStyle(fontSize: 12),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // === CREATED AT ===
              Text(
                'Dibuat: ${DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(plan.createdAt)}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),

              // === NOTES (jika ada) ===
              if (plan.notes != null && plan.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Catatan:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan.notes!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.amber[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // === ACTION BUTTONS ===
              if (showActions)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Delete button for PENDING plans
                    if (plan.status == 'PENDING')
                      ElevatedButton.icon(
                        onPressed: () =>
                            _showDeleteConfirmation(context, ref),
                        icon: const Icon(Icons.delete, size: 16),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        label: const Text('Batal'),
                      ),
                    // Ambil Perca button for APPROVED plans
                    if (plan.status == 'APPROVED')
                      ElevatedButton.icon(
                        onPressed: () => _showTakeParcaDialog(context),
                        icon: const Icon(Icons.check_circle, size: 16),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        label: const Text('Ambil Perca'),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Fetch user profile from Supabase by user ID
  Future<Map<String, dynamic>> _getUserProfile(
    dynamic supabase,
    String userId,
  ) async {
    try {
      final response = await supabase
          .from('profiles')
          .select('username, name, email')
          .eq('id', userId)
          .maybeSingle();
      return response ?? {};
    } catch (e) {
      return {};
    }
  }

  /// Show dialog untuk take parca (ambil perca)
  void _showTakeParcaDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ambil Perca'),
        content: const Text(
          'Apakah Anda ingin mengambil perca sesuai rencana ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => const AddPercaScreen(),
              ));
            },
            child: const Text('Ambil'),
          ),
        ],
      ),
    );
  }

  /// Show confirmation dialog untuk cancel plan
  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Rencana'),
        content: const Text('Apakah Anda yakin ingin membatalkan rencana ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Membatalkan rencana...'),
                    ],
                  ),
                ),
              );

              try {
                await ref.read(deletePlanProvider.notifier).deletePlan(plan.id);
                
                if (!context.mounted) return;
                
                // Close loading
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Rencana berhasil dibatalkan'),
                    backgroundColor: Colors.green,
                  ),
                );
                
                onDelete?.call();
              } catch (e) {
                if (!context.mounted) return;
                
                // Close loading
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }
}
