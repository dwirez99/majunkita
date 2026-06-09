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

  /// Filter tipe setor: 'semua', 'majun', 'limbah'
  String _selectedType = 'semua';
  
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final selectedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _dateRange,
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

    if (selectedRange != null) {
      setState(() {
        _dateRange = selectedRange;
        _currentPage = 1;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _dateRange = null;
      _currentPage = 1;
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

      // Filter berdasarkan tipe setor
      final isLimbah = item.id?.startsWith('limbah:') ?? false;
      final matchesType = _selectedType == 'semua' ||
          (_selectedType == 'limbah' && isLimbah) ||
          (_selectedType == 'majun' && !isLimbah);

      return matchesSearch && matchesDate && matchesType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(majunHistoryProvider);
    final limbahState = ref.watch(limbahHistoryProvider);
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Setor Majun'),
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat Ulang',
            onPressed: () {
              ref.invalidate(majunHistoryProvider);
              ref.invalidate(limbahHistoryProvider);
            },
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: historyState.when(
        data: (historyList) => limbahState.when(
          data: (limbahList) {
            final combinedHistory = [
              ...historyList,
              ...limbahList.map(
                (item) => MajunTransactionsModel(
                  id: 'limbah:${item.id ?? ''}',
                  idTailor: item.idTailor,
                  dateEntry: item.dateEntry,
                  weightMajun: item.weightLimbah,
                  earnedWage: 0,
                  staffId: item.staffId,
                  deliveryProof: item.deliveryProof,
                  createdAt: item.createdAt,
                  tailorName: item.tailorName,
                ),
              ),
            ]..sort((a, b) {
              final aDate = a.createdAt ?? a.dateEntry;
              final bDate = b.createdAt ?? b.dateEntry;
              return bDate.compareTo(aDate);
            });

            final filteredHistory = _applyFilters(combinedHistory);

          final totalPages = filteredHistory.isEmpty ? 1 : (filteredHistory.length / _itemsPerPage).ceil();
          
          int effectivePage = _currentPage;
          if (effectivePage > totalPages) {
            effectivePage = totalPages;
          }
          if (effectivePage < 1) effectivePage = 1;

          final startIndex = (effectivePage - 1) * _itemsPerPage;
          final endIndex = (startIndex + _itemsPerPage > filteredHistory.length)
              ? filteredHistory.length
              : startIndex + _itemsPerPage;
              
          final paginatedHistory = filteredHistory.isEmpty ? <MajunTransactionsModel>[] : filteredHistory.sublist(startIndex, endIndex);

            return Column(
            children: [
              // Filters Section
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
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
                                _currentPage = 1;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _pickDateRange,
                          icon: const Icon(Icons.date_range, size: 18),
                          label: Text(
                            _dateRange == null 
                              ? 'Tanggal' 
                              : '${DateFormat('dd/MM').format(_dateRange!.start)} - ${DateFormat('dd/MM').format(_dateRange!.end)}'
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          ),
                        ),
                        if (_dateRange != null)
                          IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.error, size: 20),
                            onPressed: _clearDateFilter,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Filter Tipe Setor
                    Row(
                      children: [
                        _buildTypeChip('semua', 'Semua'),
                        const SizedBox(width: 8),
                        _buildTypeChip('majun', 'Setor Majun'),
                        const SizedBox(width: 8),
                        _buildTypeChip('limbah', 'Setor Limbah'),
                      ],
                    ),
                  ],
                ),
              ),

              if (filteredHistory.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: AppColors.greyLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          combinedHistory.isEmpty
                              ? 'Belum ada riwayat setor majun'
                              : 'Data tidak ditemukan untuk filter saat ini.',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.greyDark,
                          ),
                        ),
                        if (combinedHistory.isEmpty) ...[
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
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: paginatedHistory.length,
                    itemBuilder: (context, index) {
                      final item = paginatedHistory[index];
                      final isLimbah =
                          item.id?.startsWith('limbah:') ?? false;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        color: AppColors.cardBackground,
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
                                          if (isLimbah)
                                            const Text(
                                              'Setor Limbah',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.orange,
                                                fontWeight: FontWeight.w600,
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
                                        label:
                                            isLimbah
                                                ? 'Berat Limbah'
                                                : 'Berat Majun',
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
                                        value:
                                            isLimbah
                                                ? '-'
                                                : currencyFormat.format(
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
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (error, _) => Center(
            child: Text(
              'Error: $error',
              style: const TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stack) => Center(
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
                onPressed: () {
                  ref.invalidate(majunHistoryProvider);
                  ref.invalidate(limbahHistoryProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String value, String label) {
    final isSelected = _selectedType == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? Colors.white : AppColors.greyDark,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceLight,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.cardBorder,
      ),
      onSelected: (_) {
        setState(() {
          _selectedType = value;
          _currentPage = 1;
        });
      },
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
    final isLimbah = item.id?.startsWith('limbah:') ?? false;
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(isLimbah ? 'Detail Setor Limbah' : 'Detail Setor Majun'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Penjahit', item.tailorName ?? 'Unknown'),
                _buildDetailRow('Tanggal', dateFormat.format(item.dateEntry)),
                _buildDetailRow(
                  isLimbah ? 'Berat Limbah' : 'Berat Majun',
                  '${item.weightMajun.toStringAsFixed(1)} KG',
                ),
                _buildDetailRow(
                  'Upah',
                  isLimbah ? '-' : currencyFormat.format(item.earnedWage),
                ),
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
