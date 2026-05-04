import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/providers/perca_provider.dart';

class AddPercaHistoryScreen extends ConsumerStatefulWidget {
  const AddPercaHistoryScreen({super.key});

  @override
  ConsumerState<AddPercaHistoryScreen> createState() =>
      _AddPercaHistoryScreenState();
}

class _AddPercaHistoryScreenState extends ConsumerState<AddPercaHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _dateRange;

  int _currentPage = 0;
  static const int _pageSize = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final selectedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDateRange: _dateRange,
      helpText: 'Pilih rentang tanggal ambil perca',
    );

    if (selectedRange != null) {
      setState(() => _dateRange = selectedRange);
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _dateRange = null;
      _currentPage = 0;
    });
  }

  DateTime? _tryParseDate(String value) {
    if (value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> records) {
    final query = _searchController.text.trim().toLowerCase();

    return records.where((record) {
      final factoryName =
          ((record['factories'] as Map<String, dynamic>?)?['factory_name'] as String? ?? '')
              .toLowerCase();
      final percaType = (record['perca_type'] as String? ?? '').toLowerCase();
      final matchesSearch =
          query.isEmpty || factoryName.contains(query) || percaType.contains(query);

      final parsedDate = _tryParseDate(record['date_entry'] as String? ?? '');
      final itemDate =
          parsedDate == null
              ? null
              : DateTime(parsedDate.year, parsedDate.month, parsedDate.day);

      final matchesDate =
          _dateRange == null ||
          (itemDate != null &&
              !itemDate.isBefore(
                DateTime(
                  _dateRange!.start.year,
                  _dateRange!.start.month,
                  _dateRange!.start.day,
                ),
              ) &&
              !itemDate.isAfter(
                DateTime(
                  _dateRange!.end.year,
                  _dateRange!.end.month,
                  _dateRange!.end.day,
                ),
              ));

      return matchesSearch && matchesDate;
    }).toList();
  }

  Widget _buildFilterSection() {
    final hasFilter = _searchController.text.isNotEmpty || _dateRange != null;
    final dateLabel =
        _dateRange == null
            ? 'Semua tanggal'
            : '${DateFormat('dd MMM yyyy').format(_dateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_dateRange!.end)}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {
              _currentPage = 0;
            }),
            decoration: InputDecoration(
              hintText: 'Cari pabrik atau tipe perca...',
              prefixIcon: const Icon(Icons.search, color: AppColors.greyDark),
              suffixIcon:
                  _searchController.text.isEmpty
                      ? null
                      : IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.greyDark),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(
                    dateLabel,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (hasFilter) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Reset'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(percaHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Ambil Perca'),
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(percaHistoryProvider),
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildFilterSection(),
            const SizedBox(height: 12),
            Expanded(
              child: historyAsync.when(
                loading:
                    () => const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                error:
                    (err, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Gagal memuat riwayat: $err',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ),
                data: (records) {
                  final filteredRecords = _applyFilters(records);
                  if (filteredRecords.isEmpty) {
                    final message =
                        records.isEmpty
                            ? 'Belum ada riwayat pengambilan perca.'
                            : 'Data tidak ditemukan untuk filter saat ini.';
                    return Center(
                      child: Text(
                        message,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.greyDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  // Group records by date + factory
                  final Map<String, List<Map<String, dynamic>>> grouped = {};
                  for (final record in filteredRecords) {
                    final dateStr = record['date_entry'] as String? ?? '';
                    final factoryName =
                        (record['factories'] as Map<String, dynamic>?)?['factory_name']
                            as String? ??
                        'Pabrik tidak diketahui';
                    final key = '$dateStr|$factoryName';
                    grouped.putIfAbsent(key, () => []).add(record);
                  }

                  final keys = grouped.keys.toList();

                  final totalPages = (keys.length / _pageSize).ceil();
                  final safePage = _currentPage.clamp(0, totalPages - 1 >= 0 ? totalPages - 1 : 0);
                  final start = safePage * _pageSize;
                  final end = (start + _pageSize).clamp(0, keys.length);
                  final pageKeys = keys.sublist(start, end);

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: pageKeys.length,
                          itemBuilder: (context, index) {
                            final key = pageKeys[index];
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
                                      Text(
                                        formattedDate,
                                        style: const TextStyle(
                                          color: AppColors.greyDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Total Input: $totalKarung Karung',
                                        style: const TextStyle(
                                          color: AppColors.greyDark,
                                        ),
                                      ),
                                      Text(
                                        'Total Berat: $totalWeight KG',
                                        style: const TextStyle(
                                          color: AppColors.greyDark,
                                        ),
                                      ),
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
                                              color: AppColors.grey,
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
                                            color: AppColors.secondary,
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
                        ),
                      ),
                      if (totalPages > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: safePage > 0
                                  ? () => setState(() => _currentPage = safePage - 1)
                                  : null,
                            ),
                            Text(
                              'Halaman ${safePage + 1} dari $totalPages',
                              style: const TextStyle(fontSize: 14, color: AppColors.greyDark),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: safePage < totalPages - 1
                                  ? () => setState(() => _currentPage = safePage + 1)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                  ],
                );
                },
              ),
            ),
          ],
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
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.black,
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
                      child: CircularProgressIndicator(color: AppColors.primary),
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
