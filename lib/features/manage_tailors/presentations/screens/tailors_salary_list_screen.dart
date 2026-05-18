import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:majunkita/features/auth/domain/providers/auth_provider.dart';
import 'package:majunkita/features/manage_majun/data/model/majun_transactions_model.dart';
import 'package:majunkita/features/manage_tailors/data/models/salary_withdrawal_model.dart';
import 'package:majunkita/features/manage_tailors/presentations/screens/widget/withdrawal_salary_dialog.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../data/models/tailor_model.dart';
import '../../domain/providers/tailor_provider.dart';

/// Screen untuk menampilkan daftar tailor (penjahit) beserta upah
class TailorsSalaryListScreen extends ConsumerStatefulWidget {
  const TailorsSalaryListScreen({super.key});

  @override
  ConsumerState<TailorsSalaryListScreen> createState() =>
      _TailorsSalaryListScreenState();
}

class _TailorsSalaryListScreenState
    extends ConsumerState<TailorsSalaryListScreen> {
  final TextEditingController _searchController = TextEditingController();

  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tailorsAsync = ref.watch(tailorsListProvider);
    final userProfile = ref.watch(userProfileProvider);
    final role = userProfile.value?['role'] ?? 'staff';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Upah & Riwayat Penjahit'),
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryDark),
            tooltip: 'Muat Ulang',
            onPressed: () => ref.invalidate(tailorsListProvider),
          ),
        ],
      ),
      body: tailorsAsync.when(
        data: (tailors) {
          // Pagination
          final totalPages =
              tailors.isEmpty ? 1 : (tailors.length / _itemsPerPage).ceil();
          int effectivePage = _currentPage.clamp(1, totalPages);
          final startIndex = (effectivePage - 1) * _itemsPerPage;
          final endIndex = (startIndex + _itemsPerPage > tailors.length)
              ? tailors.length
              : startIndex + _itemsPerPage;
          final paginatedTailors =
              tailors.isEmpty ? <TailorModel>[] : tailors.sublist(startIndex, endIndex);

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nama penjahit...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(tailorSearchQueryProvider.notifier).clear();
                              setState(() => _currentPage = 1);
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    ref
                        .read(tailorSearchQueryProvider.notifier)
                        .setQuery(value);
                    setState(() => _currentPage = 1);
                  },
                ),
              ),

              if (tailors.isEmpty)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: AppColors.greyLight),
                        SizedBox(height: 16),
                        Text(
                          'Belum ada data Penjahit.',
                          style: TextStyle(
                              fontSize: 16, color: AppColors.greyDark),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: paginatedTailors.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final tailor = paginatedTailors[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: _buildTailorCard(context, tailor, role),
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
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.greyDark),
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
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(
                'Gagal memuat: $error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(tailorsListProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTailorCard(
    BuildContext context,
    TailorModel tailor,
    String role,
  ) {
    return Card(
      elevation: 2,
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TailorSalaryHistoryScreen(tailor: tailor),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                backgroundImage:
                    tailor.tailorImages != null && tailor.tailorImages!.isNotEmpty
                        ? NetworkImage(tailor.tailorImages!)
                        : null,
                child: tailor.tailorImages == null || tailor.tailorImages!.isEmpty
                    ? Text(
                        tailor.name.isNotEmpty
                            ? tailor.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tailor.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined,
                            size: 14, color: AppColors.greyDark),
                        const SizedBox(width: 4),
                        Text(
                          'Saldo: ${CurrencyHelper.formatRupiah(tailor.balance)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.greyDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Withdraw Button
              if (role == 'admin')
                IconButton(
                  onPressed: () =>
                      WithdrawalSalaryDialog.show(context, tailor),
                  icon: const Icon(Icons.add_card, color: AppColors.primary),
                  tooltip: 'Tarik Upah',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),

              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TailorSalaryHistoryScreen — Riwayat upah satu penjahit
// ============================================================

class TailorSalaryHistoryScreen extends ConsumerStatefulWidget {
  final TailorModel tailor;
  const TailorSalaryHistoryScreen({super.key, required this.tailor});

  @override
  ConsumerState<TailorSalaryHistoryScreen> createState() =>
      _TailorSalaryHistoryScreenState();
}

class _TailorSalaryHistoryScreenState
    extends ConsumerState<TailorSalaryHistoryScreen> {
  String _selectedFilter = 'all';
  DateTimeRange? _dateRange;
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
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
    if (picked != null) {
      setState(() {
        _dateRange = picked;
        _currentPage = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync =
        ref.watch(tailorUpahHistoryProvider(widget.tailor.id));
    final dateFormat = DateFormat('dd MMM yyyy');
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Riwayat Upah: ${widget.tailor.name}'),
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.invalidate(tailorUpahHistoryProvider(widget.tailor.id)),
          ),
        ],
      ),
      body: historyAsync.when(
        data: (history) {
          final filteredHistory = history.where((item) {
            final isWithdrawal = item is SalaryWithdrawalModel;

            // Type filter
            if (_selectedFilter == 'withdrawals' && !isWithdrawal) return false;
            if (_selectedFilter == 'earnings' && isWithdrawal) return false;

            // Date filter
            if (_dateRange != null) {
              final date = isWithdrawal
                  ? (item as SalaryWithdrawalModel).dateEntry
                  : (item as MajunTransactionsModel).dateEntry;
              final justDate = DateTime(date.year, date.month, date.day);
              final start = DateTime(_dateRange!.start.year, _dateRange!.start.month, _dateRange!.start.day);
              final end = DateTime(_dateRange!.end.year, _dateRange!.end.month, _dateRange!.end.day);
              if (justDate.isBefore(start) || justDate.isAfter(end)) return false;
            }

            return true;
          }).toList();

          // Pagination
          final totalPages = filteredHistory.isEmpty
              ? 1
              : (filteredHistory.length / _itemsPerPage).ceil();
          int effectivePage = _currentPage.clamp(1, totalPages);
          final startIndex = (effectivePage - 1) * _itemsPerPage;
          final endIndex = (startIndex + _itemsPerPage > filteredHistory.length)
              ? filteredHistory.length
              : startIndex + _itemsPerPage;
          final paginatedHistory = filteredHistory.isEmpty
              ? []
              : filteredHistory.sublist(startIndex, endIndex);

          return Column(
            children: [
              // Filter Row
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type chips
                    Row(
                      children: [
                        _buildFilterChip('Semua', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Penarikan', 'withdrawals'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Pendapatan', 'earnings'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Date range row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickDateRange,
                            icon: const Icon(Icons.date_range, size: 18),
                            label: Text(
                              _dateRange == null
                                  ? 'Filter Tanggal'
                                  : '${DateFormat('dd/MM/yy').format(_dateRange!.start)} - ${DateFormat('dd/MM/yy').format(_dateRange!.end)}',
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            ),
                          ),
                        ),
                        if (_dateRange != null) ...[  
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.error, size: 20),
                            onPressed: () {
                              setState(() {
                                _dateRange = null;
                                _currentPage = 1;
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              if (filteredHistory.isEmpty)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 64, color: AppColors.greyLight),
                        SizedBox(height: 12),
                        Text(
                          'Tidak ada riwayat.',
                          style: TextStyle(
                              fontSize: 16, color: AppColors.greyDark),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    itemCount: paginatedHistory.length,
                    itemBuilder: (context, index) {
                      final item = paginatedHistory[index];
                      final isWithdrawal = item is SalaryWithdrawalModel;
                      final amount = isWithdrawal
                          ? item.amount
                          : (item as MajunTransactionsModel).earnedWage;
                      final date = isWithdrawal
                          ? item.dateEntry
                          : (item as MajunTransactionsModel).dateEntry;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 1,
                        color: AppColors.cardBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: AppColors.cardBorder),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isWithdrawal
                                ? AppColors.error.withValues(alpha: 0.12)
                                : AppColors.success.withValues(alpha: 0.12),
                            child: Icon(
                              isWithdrawal
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: isWithdrawal
                                  ? AppColors.error
                                  : AppColors.success,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            isWithdrawal
                                ? 'Penarikan Upah'
                                : 'Pendapatan dari Setoran',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            dateFormat.format(date),
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.grey),
                          ),
                          trailing: Text(
                            '${isWithdrawal ? '-' : '+'} ${currencyFormat.format(amount)}',
                            style: TextStyle(
                              color: isWithdrawal
                                  ? AppColors.error
                                  : AppColors.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
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
                            ? () => setState(
                                () => _currentPage = effectivePage - 1)
                            : null,
                      ),
                      Text(
                        'Halaman $effectivePage dari $totalPages',
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.greyDark),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: effectivePage < totalPages
                            ? () => setState(
                                () => _currentPage = effectivePage + 1)
                            : null,
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(
                'Error: $error',
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => ref
                    .invalidate(tailorUpahHistoryProvider(widget.tailor.id)),
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
          _currentPage = 1;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.greyLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.white : AppColors.primaryDark,
          ),
        ),
      ),
    );
  }
}
