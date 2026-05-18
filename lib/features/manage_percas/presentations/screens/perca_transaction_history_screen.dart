import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/providers/perca_transactions_provider.dart';

class PercaTransactionHistoryScreen extends ConsumerStatefulWidget {
  const PercaTransactionHistoryScreen({super.key});

  @override
  ConsumerState<PercaTransactionHistoryScreen> createState() => _PercaTransactionHistoryScreenState();
}

class _PercaTransactionHistoryScreenState extends ConsumerState<PercaTransactionHistoryScreen> {
  int _currentPage = 1;
  static const int _itemsPerPage = 10;
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
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
        error: (err, _) => Center(
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
                  onPressed: () => ref.invalidate(percaTransactionHistoryProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (records) {
          // Filter records
          var filteredRecords = records;

          if (_selectedDateRange != null) {
            filteredRecords = filteredRecords.where((record) {
              final dateStr = record['date_entry'] as String? ?? '';
              if (dateStr.isEmpty) return false;
              final date = DateTime.tryParse(dateStr);
              if (date == null) return false;
              
              final justDate = DateTime(date.year, date.month, date.day);
              final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
              final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day);
              
              return justDate.isAfter(start.subtract(const Duration(days: 1))) && 
                     justDate.isBefore(end.add(const Duration(days: 1)));
            }).toList();
          }

          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            filteredRecords = filteredRecords.where((record) {
              final tailorName = (record['tailors'] as Map<String, dynamic>?)?['name']?.toString().toLowerCase() ?? '';
              return tailorName.contains(query);
            }).toList();
          }

          // Group records by date + tailor id
          final Map<String, List<Map<String, dynamic>>> grouped = {};
          for (final record in filteredRecords) {
            final dateStr = record['date_entry'] as String? ?? '';
            final tailorId = record['id_tailors'] as String? ?? '';
            final key = '$dateStr|$tailorId';
            grouped.putIfAbsent(key, () => []).add(record);
          }

          final keys = grouped.keys.toList();
          
          // Pagination logic
          final totalPages = keys.isEmpty ? 1 : (keys.length / _itemsPerPage).ceil();
          
          // Ensure current page is valid
          int effectivePage = _currentPage;
          if (effectivePage > totalPages) {
            effectivePage = totalPages;
          }
          if (effectivePage < 1) effectivePage = 1;

          final startIndex = (effectivePage - 1) * _itemsPerPage;
          final endIndex = (startIndex + _itemsPerPage > keys.length)
              ? keys.length
              : startIndex + _itemsPerPage;
              
          final paginatedKeys = keys.isEmpty ? <String>[] : keys.sublist(startIndex, endIndex);

          return Column(
            children: [
              // Filters Section
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Cari penjahit...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                            _currentPage = 1;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                          initialDateRange: _selectedDateRange,
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppColors.primary,
                                  onPrimary: Colors.white,
                                  onSurface: Colors.black,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDateRange = picked;
                            _currentPage = 1;
                          });
                        }
                      },
                      icon: const Icon(Icons.date_range, size: 18),
                      label: Text(
                        _selectedDateRange == null 
                          ? 'Tanggal' 
                          : '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}'
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      ),
                    ),
                    if (_selectedDateRange != null)
                      IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.error, size: 20),
                        onPressed: () {
                          setState(() {
                            _selectedDateRange = null;
                            _currentPage = 1;
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),

              if (keys.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          size: 60,
                          color: AppColors.greyLight,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum ada riwayat transaksi perca.',
                          style: TextStyle(fontSize: 16, color: AppColors.greyDark),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: paginatedKeys.length,
                    itemBuilder: (context, index) {
                      final key = paginatedKeys[index];
                      final parts = key.split('|');
                      final dateStr = parts[0];
                      final items = grouped[key]!;
                      
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
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: AppColors.greyDark,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      formattedDate,
                                      style: const TextStyle(
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
                                      style: const TextStyle(
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
                  ),
                ),

              // Pagination Controls
              if (totalPages > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: effectivePage > 1
                            ? () => setState(() => _currentPage = effectivePage - 1)
                            : null,
                      ),
                      Text(
                        'Halaman $effectivePage dari $totalPages',
                        style: const TextStyle(fontSize: 14, color: AppColors.greyDark),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: effectivePage < totalPages
                            ? () => setState(() => _currentPage = effectivePage + 1)
                            : null,
                      ),
                    ],
                  ),
                ),
            ],
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
