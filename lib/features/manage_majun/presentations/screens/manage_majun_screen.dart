import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/providers/majun_provider.dart';
import 'setor_majun_screen.dart';
import 'setor_limbah_screen.dart';
import 'majun_history_screen.dart';

/// Screen utama untuk manajemen majun
/// Hub yang menampilkan menu dan statistik
class ManageMajunScreen extends ConsumerWidget {
  const ManageMajunScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priceState = ref.watch(majunPricePerKgProvider);
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Manajemen Majun',
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
              ref.invalidate(majunMonthlyStatsProvider);
              ref.invalidate(majunHistoryProvider);
              ref.invalidate(majunPricePerKgProvider);
              ref.invalidate(tailorListForMajunProvider);
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
              // Menu Grid
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
                    icon: Icons.add_circle,
                    title: 'Setor\nMajun',
                    color: AppColors.secondary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SetorMajunScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context: context,
                    icon: Icons.delete_outline,
                    title: 'Setor\nLimbah',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SetorLimbahScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context: context,
                    icon: Icons.history,
                    title: 'Riwayat\nSetor Majun',
                    color: AppColors.accent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MajunHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context: context,
                    icon: Icons.monetization_on,
                    title: 'Harga\nMajun/KG',
                    color: Colors.amber,
                    onTap:
                        () => _showEditPriceDialog(
                          context,
                          ref,
                          priceState.value ?? 0,
                        ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Stok Perca Penjahit ──
              _buildTailorStockSection(ref, currencyFormat),

              const SizedBox(height: 24),

              // Statistik
              const Text(
                'Statistik Majun (12 Bulan Terakhir)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Stats chart area
              ref
                  .watch(majunMonthlyStatsProvider)
                  .when(
                    data: (stats) {
                      if (stats.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.bar_chart_outlined,
                                  size: 60,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Belum ada data setor majun',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return _buildStatsView(stats);
                    },
                    loading:
                        () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    error:
                        (error, stack) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 40,
                                  color: Colors.red[300],
                                ),
                                const SizedBox(height: 8),
                                Text('Error: $error'),
                              ],
                            ),
                          ),
                        ),
                  ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Edit Price Dialog ──
  void _showEditPriceDialog(
    BuildContext context,
    WidgetRef ref,
    double currentPrice,
  ) {
    final controller = TextEditingController(
      text: currentPrice.toStringAsFixed(0),
    );
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final newPrice = double.tryParse(controller.text) ?? 0;
            final isChanged = newPrice != currentPrice && newPrice > 0;

            return AlertDialog(
              title: const Text('Ubah Harga Majun per KG'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current price
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Harga saat ini:',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          currencyFormat.format(currentPrice),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // New price input
                  const Text(
                    'Harga Baru (Rupiah)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      prefixText: 'Rp',
                      suffixText: '/ KG',
                      hintText: 'Masukkan harga baru',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setDialogState(() {}),
                  ),

                  // Preview
                  if (isChanged) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.green[700],
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Harga baru: ${currencyFormat.format(newPrice)} / KG',
                            style: TextStyle(
                              color: Colors.green[800],
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('BATAL'),
                ),
                ElevatedButton(
                  onPressed:
                      isChanged
                          ? () async {
                            Navigator.of(ctx).pop();
                            try {
                              await ref
                                  .read(updatePriceNotifierProvider.notifier)
                                  .updatePrice(newPrice);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Harga berhasil diubah ke ${currencyFormat.format(newPrice)}/KG',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal mengubah harga: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('SIMPAN'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Stok Perca Penjahit Section ──
  Widget _buildTailorStockSection(WidgetRef ref, NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.inventory_2, size: 22, color: Colors.teal),
            const SizedBox(width: 8),
            const Text(
              'Stok Perca Penjahit',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ref
            .watch(tailorListForMajunProvider)
            .when(
              data: (tailors) {
                if (tailors.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 40,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Belum ada data penjahit',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Sort tailors by stock (highest first)
                final sorted = [...tailors]
                  ..sort((a, b) => b.totalStock.compareTo(a.totalStock));

                final totalStock = sorted.fold<double>(
                  0,
                  (s, t) => s + t.totalStock,
                );
                final totalBalance = sorted.fold<double>(
                  0,
                  (s, t) => s + t.balance,
                );

                return Column(
                  children: [
                    // Summary row
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.teal.withValues(alpha: 0.1),
                            Colors.teal.withValues(alpha: 0.04),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.teal.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Icon(
                                Icons.people,
                                color: Colors.teal,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${sorted.length}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                              Text(
                                'Penjahit',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.teal.withValues(alpha: 0.2),
                          ),
                          Column(
                            children: [
                              const Icon(
                                Icons.scale,
                                color: Colors.teal,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${totalStock.toStringAsFixed(1)} KG',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                              Text(
                                'Total Stok',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.teal.withValues(alpha: 0.2),
                          ),
                          Column(
                            children: [
                              const Icon(
                                Icons.account_balance_wallet,
                                color: Colors.teal,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currencyFormat.format(totalBalance),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                              Text(
                                'Total Saldo',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Tailor list
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sorted.length,
                      itemBuilder: (context, index) {
                        final tailor = sorted[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.teal[50],
                                backgroundImage:
                                    tailor.tailorImages != null &&
                                            tailor.tailorImages!.isNotEmpty
                                        ? NetworkImage(tailor.tailorImages!)
                                        : null,
                                child:
                                    tailor.tailorImages == null ||
                                            tailor.tailorImages!.isEmpty
                                        ? Text(
                                          tailor.name.isNotEmpty
                                              ? tailor.name[0].toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal[700],
                                          ),
                                        )
                                        : null,
                              ),
                              const SizedBox(width: 12),

                              // Name
                              Expanded(
                                child: Text(
                                  tailor.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              // Stock
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${tailor.totalStock.toStringAsFixed(1)} KG',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          tailor.totalStock > 0
                                              ? Colors.teal[700]
                                              : Colors.grey[500],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    currencyFormat.format(tailor.balance),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          tailor.balance > 0
                                              ? Colors.amber[800]
                                              : Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
              loading:
                  () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              error:
                  (error, _) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Error: $error',
                        style: TextStyle(color: Colors.red[400]),
                      ),
                    ),
                  ),
            ),
      ],
    );
  }

  Widget _buildStatsView(Map<String, double> stats) {
    // Sort by month key
    final sortedEntries =
        stats.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    // Take last 12 months
    final recentEntries =
        sortedEntries.length > 12
            ? sortedEntries.sublist(sortedEntries.length - 12)
            : sortedEntries;

    // Total
    final totalWeight = recentEntries.fold<double>(
      0,
      (sum, e) => sum + e.value,
    );

    return Column(
      children: [
        // Summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.secondary.withValues(alpha: 0.1),
                AppColors.secondary.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Icon(Icons.scale, color: AppColors.secondary, size: 28),
                  const SizedBox(height: 4),
                  Text(
                    '${totalWeight.toStringAsFixed(1)} KG',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  Text(
                    'Total Berat',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
              Container(
                width: 1,
                height: 50,
                color: AppColors.secondary.withValues(alpha: 0.2),
              ),
              Column(
                children: [
                  Icon(
                    Icons.calendar_month,
                    color: AppColors.secondary,
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${recentEntries.length}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  Text(
                    'Bulan Aktif',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Monthly list
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentEntries.length,
          itemBuilder: (context, index) {
            // Display in reverse (newest first)
            final entry = recentEntries[recentEntries.length - 1 - index];
            final monthLabel = _formatMonthKey(entry.key);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        monthLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '${entry.value.toStringAsFixed(1)} KG',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 60,
                        child: LinearProgressIndicator(
                          value:
                              totalWeight > 0 ? entry.value / totalWeight : 0,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatMonthKey(String key) {
    try {
      final parts = key.split('-');
      final year = parts[0];
      final month = int.parse(parts[1]);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '${months[month - 1]} $year';
    } catch (e) {
      return key;
    }
  }

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
            crossAxisAlignment: CrossAxisAlignment.center,
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
}
