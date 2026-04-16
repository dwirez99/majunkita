import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:majunkita/features/auth/domain/providers/auth_provider.dart';
import 'package:majunkita/features/manage_majun/data/model/majun_transactions_model.dart';
import 'package:majunkita/features/manage_tailors/data/models/salary_withdrawal_model.dart';
import 'package:majunkita/features/manage_tailors/presentations/screens/widget/withdrawal_salary_dialog.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../data/models/tailor_model.dart';
import '../../domain/providers/tailor_provider.dart';

/// Screen untuk menampilkan daftar tailor (penjahit)
class TailorsSalaryListScreen extends ConsumerStatefulWidget {
  const TailorsSalaryListScreen({super.key});

  @override
  ConsumerState<TailorsSalaryListScreen> createState() =>
      _TailorsSalaryListScreenState();
}

class _TailorsSalaryListScreenState
    extends ConsumerState<TailorsSalaryListScreen> {
  final TextEditingController _searchController = TextEditingController();

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Upah & Riwayat Penjahit',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.grey[200],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SEARCH BAR ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Cari nama penjahit...',
                        ),
                        onChanged: (value) {
                          // Update Query di Provider
                          ref
                              .read(tailorSearchQueryProvider.notifier)
                              .setQuery(value);
                        },
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(tailorSearchQueryProvider.notifier).clear();
                        },
                      )
                    else
                      const Icon(Icons.search, color: Colors.grey),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // --- TOMBOL REFRESH ---
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    // Paksa refresh data
                    ref.invalidate(tailorsListProvider);
                  },
                  icon: const Icon(Icons.refresh, color: Colors.black),
                  label: const Text(
                    'Refresh Data',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // --- LIST VIEW ---
              Expanded(
                child: tailorsAsync.when(
                  data: (tailors) {
                    if (tailors.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.people_outline,
                              size: 60,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'Belum ada data Penjahit.'
                                  : 'Penjahit "${_searchController.text}" tidak ditemukan.',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: tailors.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final tailor = tailors[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildTailorCard(context, tailor, role),
                        );
                      },
                    );
                  },
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error:
                      (error, stack) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Gagal memuat: $error',
                              textAlign: TextAlign.center,
                            ),
                            ElevatedButton(
                              onPressed:
                                  () => ref.invalidate(tailorsListProvider),
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
                ),
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
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TailorSalaryHistoryScreen(tailor: tailor),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[400],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.white,
              backgroundImage:
                  tailor.tailorImages != null && tailor.tailorImages!.isNotEmpty
                      ? NetworkImage(tailor.tailorImages!)
                      : null,
              child:
                  tailor.tailorImages == null || tailor.tailorImages!.isEmpty
                      ? Text(
                        tailor.name.isNotEmpty
                            ? tailor.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      )
                      : null,
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tailor.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total Saldo: ${CurrencyHelper.formatRupiah(tailor.balance)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Add Salary Button
            if (role == 'admin')
              IconButton(
                onPressed: () => WithdrawalSalaryDialog.show(context, tailor),
                icon: const Icon(Icons.add_card, color: Colors.white),
                tooltip: 'Tarik Upah',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.1),
                ),
              ),

            const SizedBox(width: 4),

            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(tailorUpahHistoryProvider(widget.tailor.id));

    return Scaffold(
      appBar: AppBar(title: Text('Riwayat Upah: ${widget.tailor.name}')),
      body: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8.0,
              children: [
                FilterChip(
                  label: const Text('Semua'),
                  selected: _selectedFilter == 'all',
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedFilter = 'all');
                  },
                ),
                FilterChip(
                  label: const Text('Penarikan'),
                  selected: _selectedFilter == 'withdrawals',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedFilter = 'withdrawals');
                    }
                  },
                ),
                FilterChip(
                  label: const Text('Pendapatan'),
                  selected: _selectedFilter == 'earnings',
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedFilter = 'earnings');
                  },
                ),
              ],
            ),
          ),
          // History List
          Expanded(
            child: historyAsync.when(
              data: (history) {
                final filteredHistory = history.where((item) {
                  if (_selectedFilter == 'all') return true;
                  final isWithdrawal = item is SalaryWithdrawalModel;
                  if (_selectedFilter == 'withdrawals') return isWithdrawal;
                  return !isWithdrawal; // 'earnings'
                }).toList();

                if (filteredHistory.isEmpty) {
                  return const Center(child: Text('Tidak ada riwayat.'));
                }
                return ListView.builder(
                  itemCount: filteredHistory.length,
                  itemBuilder: (context, index) {
                    final item = filteredHistory[index];
                    final isWithdrawal = item is SalaryWithdrawalModel;
                    final amount =
                        isWithdrawal
                            ? item.amount
                            : (item as MajunTransactionsModel).earnedWage;
                    final date =
                        isWithdrawal
                            ? item.dateEntry
                            : (item as MajunTransactionsModel).dateEntry;

                    return ListTile(
                      leading: Icon(
                        isWithdrawal
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: isWithdrawal ? Colors.red : Colors.green,
                      ),
                      title: Text(
                        isWithdrawal
                            ? 'Penarikan Upah'
                            : 'Pendapatan dari Setoran',
                      ),
                      subtitle: Text('${date.day}/${date.month}/${date.year}'),
                      trailing: Text(
                        '${isWithdrawal ? '-' : '+'} ${CurrencyHelper.formatRupiah(amount)}',
                        style: TextStyle(
                          color: isWithdrawal ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}
