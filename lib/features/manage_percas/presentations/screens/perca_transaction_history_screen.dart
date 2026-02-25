import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/providers/perca_transactions_provider.dart';

class PercaTransactionHistoryScreen extends ConsumerWidget {
  const PercaTransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(percaTransactionHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi Perca'),
        backgroundColor: Colors.green[400],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(percaTransactionHistoryProvider),
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 12),
                    Text(
                      'Gagal memuat riwayat: $err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
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
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada riwayat transaksi perca.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          // Group records by date + tailor
          final Map<String, List<Map<String, dynamic>>> grouped = {};
          for (final record in records) {
            final dateStr = record['date_entry'] as String? ?? '';
            final tailorName =
                (record['tailors'] as Map<String, dynamic>?)?['name']
                    as String? ??
                'Penjahit tidak diketahui';
            final key = '$dateStr|$tailorName';
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
              final tailorName = parts[1];
              final items = grouped[key]!;

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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: Icon(Icons.person, color: Colors.green[700]),
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
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildInfoChip(
                              '$totalItems item',
                              Colors.blue[100]!,
                              Colors.blue[800]!,
                            ),
                            const SizedBox(width: 8),
                            _buildInfoChip(
                              '${totalWeight.toStringAsFixed(1)} KG',
                              Colors.green[100]!,
                              Colors.green[800]!,
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
                          color: Colors.green[400],
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
                                color: Colors.grey[600],
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
