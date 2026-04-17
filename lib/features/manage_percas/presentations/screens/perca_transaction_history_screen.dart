import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/providers/perca_transactions_provider.dart';

class PercaTransactionHistoryScreen extends ConsumerWidget {
  const PercaTransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(percaTransactionHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi Perca'),
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(percaTransactionHistoryProvider),
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error:
            (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text(
                      'Gagal memuat riwayat: $err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: AppColors.greyDark),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed:
                          () => ref.invalidate(percaTransactionHistoryProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
        data: (records) {
          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 60,
                    color: AppColors.greyLight,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada riwayat transaksi perca.',
                    style: const TextStyle(fontSize: 16, color: AppColors.greyDark),
                  ),
                ],
              ),
            );
          }

          // Group records by date + tailor id (not name, to avoid merging different tailors with same name)
          final Map<String, List<Map<String, dynamic>>> grouped = {};
          for (final record in records) {
            final dateStr = record['date_entry'] as String? ?? '';
            final tailorId = record['id_tailors'] as String? ?? '';
            final key = '$dateStr|$tailorId';
            grouped.putIfAbsent(key, () => []).add(record);
          }

          final keys = grouped.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final key = keys[index];
              final parts = key.split('|');
              final dateStr = parts[0];
              final items = grouped[key]!;
              // Derive tailor name from the first record in the group
              final tailorName =
                  (items.first['tailors'] as Map<String, dynamic>?)?['name']
                      as String? ??
                  'Penjahit tidak diketahui';

              final formattedDate = _formatDate(dateStr);
              double totalWeight = 0;
              int totalItems = items.length;
              final Map<String, double> weightByType = {};
              final Map<String, int> countByType = {};

              for (final item in items) {
                final type = item['percas_type'] as String? ?? '-';
                final weight = (item['weight'] as num?)?.toDouble() ?? 0;
                totalWeight += weight;
                weightByType[type] = (weightByType[type] ?? 0) + weight;
                countByType[type] = (countByType[type] ?? 0) + 1;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                color: AppColors.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.cardBorder),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: const Icon(Icons.person, color: AppColors.primaryDark),
                  ),
                  title: Text(
                    tailorName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: AppColors.greyDark,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.greyDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildInfoChip(
                              '$totalItems item',
                              AppColors.info.withValues(alpha: 0.15),
                              AppColors.info,
                            ),
                            const SizedBox(width: 8),
                            _buildInfoChip(
                              '${totalWeight.toStringAsFixed(1)} KG',
                              AppColors.primary.withValues(alpha: 0.15),
                              AppColors.primaryDark,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  children: [
                    const Divider(height: 1),
                    ...weightByType.entries.map((entry) {
                      final type = entry.key;
                      final weight = entry.value;
                      final count = countByType[type] ?? 0;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 2,
                        ),
                        leading: Icon(
                          type.toLowerCase() == 'kaos'
                              ? Icons.checkroom
                              : Icons.content_cut,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        title: Text(
                          type,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$count Karung',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${weight.toStringAsFixed(1)} KG',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                color: AppColors.greyDark,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }
}
