import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/providers/perca_provider.dart';

class AddPercaHistoryScreen extends ConsumerWidget {
  const AddPercaHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(percaHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Ambil Perca'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(percaHistoryProvider),
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Gagal memuat riwayat: $err',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        data: (records) {
          if (records.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada riwayat pengambilan perca.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          // Group records by date + factory
          final Map<String, List<Map<String, dynamic>>> grouped = {};
          for (final record in records) {
            final dateStr = record['date_entry'] as String? ?? '';
            final factoryName =
                (record['factories'] as Map<String, dynamic>?)?['factory_name']
                    as String? ??
                'Pabrik tidak diketahui';
            final key = '$dateStr|$factoryName';
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
              final factoryName = parts[1];
              final items = grouped[key]!;

              final formattedDate = _formatDate(dateStr);
              double totalWeight = 0;
              int totalKarung = items.length;
              final Map<String, double> weightByType = {};
              final Map<String, int> karungByType = {};
              String proofUrl = '';

              for (final item in items) {
                final type = item['perca_type'] as String? ?? '-';
                final weight = (item['weight'] as num?)?.toDouble() ?? 0;
                totalWeight += weight;
                weightByType[type] = (weightByType[type] ?? 0) + weight;
                karungByType[type] = (karungByType[type] ?? 0) + 1;
                if (proofUrl.isEmpty) {
                  final url = item['delivery_proof'] as String? ?? '';
                  if (url.isNotEmpty) {
                    proofUrl = url;
                  }
                }
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  title: Text(
                    factoryName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(formattedDate),
                        const SizedBox(height: 4),
                        Text('Total Input: $totalKarung Karung'),
                        Text('Total Berat: $totalWeight KG'),
                      ],
                    ),
                  ),
                  children: [
                    ...weightByType.entries.map((entry) {
                      final type = entry.key;
                      final weight = entry.value;
                      final karung = karungByType[type] ?? 0;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 4,
                        ),
                        title: Text('Total $type'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$karung Karung',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '$weight KG',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (proofUrl.isNotEmpty)
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 0,
                        ),
                        title: GestureDetector(
                          onTap: () => _showProofImage(context, proofUrl),
                          child: const Text(
                            'Lihat Bukti Foto',
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        dense: true,
                      ),
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

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
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
                  semanticLabel: 'Bukti foto pengambilan perca',
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
}
