import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/model/majun_transactions_model.dart';
import '../../domain/providers/majun_provider.dart';

/// Screen untuk menampilkan riwayat setor majun
class MajunHistoryScreen extends ConsumerWidget {
  const MajunHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(majunHistoryProvider);
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Setor Majun'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat Ulang',
            onPressed: () => ref.invalidate(majunHistoryProvider),
          ),
        ],
      ),
      body: historyState.when(
        data: (historyList) {
          if (historyList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada riwayat setor majun',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Riwayat akan muncul setelah ada setoran',
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              final item = historyList[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.cardBorder),
                ),
                child: InkWell(
                  onTap:
                      () => _showDetailDialog(
                        context,
                        item,
                        currencyFormat,
                        dateFormat,
                      ),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: Tailor name + Date
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.secondary.withValues(
                                alpha: 0.1,
                              ),
                              child: const Icon(
                                Icons.person,
                                color: AppColors.secondary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.tailorName ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    dateFormat.format(item.dateEntry),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),

                        // Data: Berat Majun + Upah
                        Row(
                          children: [
                            Expanded(
                              child: _buildDataColumn(
                                icon: Icons.scale,
                                label: 'Berat Majun',
                                value:
                                    '${item.weightMajun.toStringAsFixed(1)} KG',
                                color: AppColors.secondary,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey[200],
                            ),
                            Expanded(
                              child: _buildDataColumn(
                                icon: Icons.monetization_on,
                                label: 'Upah',
                                value: currencyFormat.format(item.earnedWage),
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),

                        // Foto Bukti (link)
                        if (item.deliveryProof != null &&
                            item.deliveryProof!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap:
                                () => _showProofImage(
                                  context,
                                  item.deliveryProof!,
                                ),
                            child: const Text(
                              'Lihat Bukti Foto',
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 12),
                  Text('Error: $error'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => ref.invalidate(majunHistoryProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildDataColumn({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  void _showDetailDialog(
    BuildContext context,
    MajunTransactionsModel item,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Detail Setor Majun'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Penjahit', item.tailorName ?? 'Unknown'),
                _buildDetailRow('Tanggal', dateFormat.format(item.dateEntry)),
                _buildDetailRow(
                  'Berat Majun',
                  '${item.weightMajun.toStringAsFixed(1)} KG',
                ),
                _buildDetailRow('Upah', currencyFormat.format(item.earnedWage)),
                if (item.deliveryProof != null &&
                    item.deliveryProof!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _showProofImage(context, item.deliveryProof!);
                    },
                    child: const Text(
                      'Lihat Bukti Foto',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('TUTUP'),
              ),
            ],
          ),
    );
  }

  void _showProofImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: const Text('Bukti Foto'),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Image.network(
                  url,
                  loadingBuilder: (ctx, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    );
                  },
                  errorBuilder:
                      (_, __, ___) => const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Gagal memuat gambar'),
                      ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.greyDark, fontSize: 13),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
