import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/expedition_model.dart';
import '../../domain/expedition_provider.dart';
import 'add_expedition_screen.dart';
import 'expedition_history_screen.dart';

/// Screen hub untuk Manage Expeditions.
/// Menampilkan menu navigasi dan ringkasan statistik pengiriman,
/// mengikuti pola ManagePercaScreen / ManageMajunScreen.
class ManageExpeditionsScreen extends ConsumerWidget {
  const ManageExpeditionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expeditionsAsync = ref.watch(expeditionListProvider);
    final weightAsync = ref.watch(weightPerSackProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Manajemen Expedisi',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.grey[200],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.grey),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            tooltip: 'Muat Ulang Data',
            onPressed: () {
              ref.invalidate(expeditionListProvider);
              ref.invalidate(weightPerSackProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data sedang dimuat ulang...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Menu Grid ────────────────────────────────────────────────
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.5,
                children: [
                  _buildMenuCard(
                    context: context,
                    icon: Icons.add_road,
                    title: 'Tambah\nExpedisi',
                    color: AppColors.secondary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddExpeditionScreen(),
                      ),
                    ),
                  ),
                  _buildMenuCard(
                    context: context,
                    icon: Icons.history,
                    title: 'Riwayat\nExpedisi',
                    color: AppColors.accent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ExpeditionHistoryScreen(),
                      ),
                    ),
                  ),
                  _buildMenuCard(
                    context: context,
                    icon: Icons.scale,
                    title: 'Berat\nper Karung',
                    color: Colors.teal,
                    onTap: () => _showEditWeightDialog(
                      context,
                      ref,
                      weightAsync.value ?? 50,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Statistik Ringkasan ──────────────────────────────────────
              const Text(
                'Ringkasan Pengiriman',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              expeditionsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.error_outline,
                            size: 40, color: Colors.red[300]),
                        const SizedBox(height: 8),
                        Text(
                          'Gagal memuat data: $error',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red[400]),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () =>
                              ref.invalidate(expeditionListProvider),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (expeditions) =>
                    _buildSummarySection(expeditions),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Summary cards + recent list ──────────────────────────────────────────

  Widget _buildSummarySection(List<ExpeditionModel> expeditions) {
    final totalSacks =
        expeditions.fold<int>(0, (sum, e) => sum + e.sackNumber);
    final totalWeight =
        expeditions.fold<int>(0, (sum, e) => sum + e.totalWeight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stat cards row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.local_shipping,
                label: 'Total Pengiriman',
                value: '${expeditions.length}',
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.inventory_2_outlined,
                label: 'Total Karung',
                value: '$totalSacks',
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.scale,
                label: 'Total Berat',
                value: '$totalWeight kg',
                color: AppColors.primary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Recent 5 expeditions
        if (expeditions.isNotEmpty) ...[
          const Text(
            'Pengiriman Terbaru',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          ...expeditions.take(5).map(_buildRecentTile),
        ] else
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.local_shipping_outlined,
                      size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada data expedisi',
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTile(ExpeditionModel expedition) {
    final dateFormatted =
        DateFormat('dd MMM yyyy').format(expedition.expeditionDate);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
          child:
              const Icon(Icons.local_shipping, color: AppColors.secondary),
        ),
        title: Text(
          expedition.destination,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '$dateFormatted  ·  ${expedition.sackNumber} karung  ·  ${expedition.totalWeight} kg',
          style: const TextStyle(fontSize: 12, color: AppColors.grey),
        ),
        trailing: expedition.partnerName != null
            ? Text(
                expedition.partnerName!,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.greyDark),
              )
            : null,
      ),
    );
  }

  // ── Shared menu card builder ─────────────────────────────────────────────

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.cardBorder, width: 1),
      ),
      color: AppColors.cardBackground,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Edit weight-per-sack dialog ──────────────────────────────────────────

  void _showEditWeightDialog(
      BuildContext context, WidgetRef ref, int currentWeight) {
    final controller =
        TextEditingController(text: currentWeight.toString());

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final newWeight = int.tryParse(controller.text) ?? 0;
          final isChanged = newWeight != currentWeight && newWeight > 0;

          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            title: const Text(
              'Ubah Berat per Karung',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current value display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.scale,
                          size: 16, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text(
                        'Saat ini: $currentWeight kg / karung',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Input field
                TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Berat Baru',
                    suffixText: 'kg / karung',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Colors.teal, width: 2),
                    ),
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 8),

                // Preview of new value
                if (isChanged)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.teal.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Baru: $newWeight kg / karung',
                      style: const TextStyle(
                          fontSize: 13,
                          color: Colors.teal,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('BATAL'),
              ),
              ElevatedButton(
                onPressed: isChanged
                    ? () async {
                        Navigator.pop(ctx);
                        try {
                          await ref
                              .read(updateWeightPerSackProvider.notifier)
                              .updateWeight(newWeight);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Berat per karung diperbarui: $newWeight kg'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal memperbarui: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white),
                child: const Text('SIMPAN'),
              ),
            ],
          );
        },
      ),
    );
  }
}
