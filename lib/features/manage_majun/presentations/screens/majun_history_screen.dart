import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/model/majun_transactions_model.dart';
import '../../domain/providers/majun_provider.dart';

/// Screen untuk menampilkan riwayat setor majun
class MajunHistoryScreen extends ConsumerStatefulWidget {
  const MajunHistoryScreen({super.key});

  @override
  ConsumerState<MajunHistoryScreen> createState() => _MajunHistoryScreenState();
}

class _MajunHistoryScreenState extends ConsumerState<MajunHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _dateRange;

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
      helpText: 'Pilih rentang tanggal setor',
    );

    if (selectedRange != null) {
      setState(() => _dateRange = selectedRange);
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _dateRange = null;
    });
  }

  List<MajunTransactionsModel> _applyFilters(List<MajunTransactionsModel> history) {
    final query = _searchController.text.trim().toLowerCase();

    return history.where((item) {
      final tailorName = (item.tailorName ?? '').toLowerCase();
      final matchesSearch = query.isEmpty || tailorName.contains(query);

      final itemDate = DateTime(
        item.dateEntry.year,
        item.dateEntry.month,
        item.dateEntry.day,
      );
      final matchesDate =
          _dateRange == null ||
          (!itemDate.isBefore(
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
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Cari nama penjahit...',
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
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat Ulang',
            onPressed: () => ref.invalidate(majunHistoryProvider),
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFilterSection(),
            const SizedBox(height: 12),
            Expanded(
              child: historyState.when(
                data: (historyList) {
                  final filteredHistory = _applyFilters(historyList);

                  if (filteredHistory.isEmpty) {
                    final emptyMessage =
                        historyList.isEmpty
                            ? 'Belum ada riwayat setor majun'
                            : 'Data tidak ditemukan untuk filter saat ini.';
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: AppColors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            emptyMessage,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.greyDark,
                            ),
                          ),
                          if (historyList.isEmpty) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Riwayat akan muncul setelah ada setoran',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredHistory.length,
                    itemBuilder: (context, index) {
                      final item = filteredHistory[index];
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
                                      backgroundColor: AppColors.secondary
                                          .withValues(alpha: 0.1),
                                      child: const Icon(
                                        Icons.person,
                                        color: AppColors.secondary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.grey,
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
                                      color: AppColors.cardBorder,
                                    ),
                                    Expanded(
                                      child: _buildDataColumn(
                                        icon: Icons.monetization_on,
                                        label: 'Upah',
                                        value: currencyFormat.format(
                                          item.earnedWage,
                                        ),
                                        color: AppColors.accentDark,
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
                                        color: AppColors.secondary,
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
                loading:
                    () => const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                error:
                    (error, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Error: $error',
                            style: const TextStyle(color: AppColors.error),
                            textAlign: TextAlign.center,
                          ),
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
            ),
          ],
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
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.grey),
        ),
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
                        color: AppColors.secondary,
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
