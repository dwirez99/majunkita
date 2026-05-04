import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/factory_model.dart';
import '../../domain/providers/factory_provider.dart';
import 'factory_form_dialog.dart';

class FactoryListScreen extends ConsumerStatefulWidget {
  const FactoryListScreen({super.key});

  @override
  ConsumerState<FactoryListScreen> createState() => _FactoryListScreenState();
}

class _FactoryListScreenState extends ConsumerState<FactoryListScreen> {
  final TextEditingController _searchController = TextEditingController();
  static const int _pageSize = 5;
  int _currentPage = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final factoriesAsync = ref.watch(factoriesListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Kelola Data Pabrik',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- TOMBOL TAMBAH PABRIK ---
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () => _showFactoryFormDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Tambah Pabrik',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- SEARCH BAR ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Cari nama pabrik...',
                        ),
                        onChanged: (value) {
                          ref
                              .read(factorySearchQueryProvider.notifier)
                              .setQuery(value);
                          setState(() => _currentPage = 0);
                        },
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.grey),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(factorySearchQueryProvider.notifier)
                              .clear();
                          setState(() => _currentPage = 0);
                        },
                      )
                    else
                      const Icon(Icons.search, color: AppColors.grey),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // --- REFRESH BUTTON ---
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    ref.invalidate(factoriesListProvider);
                  },
                  icon: const Icon(Icons.refresh, color: AppColors.primaryDark),
                  label: const Text(
                    'Refresh Data',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // --- FACTORY LIST ---
              Expanded(
                child: factoriesAsync.when(
                  data: (factories) {
                    if (factories.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.factory_outlined,
                              size: 60,
                              color: AppColors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'Belum ada data Pabrik.'
                                  : 'Pabrik "${_searchController.text}" tidak ditemukan.',
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final totalPages = (factories.length / _pageSize).ceil();
                    final safePage = _currentPage.clamp(0, totalPages - 1);
                    final start = safePage * _pageSize;
                    final end = (start + _pageSize).clamp(0, factories.length);
                    final pageFactories = factories.sublist(start, end);

                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: pageFactories.length,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final factory = pageFactories[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: _buildFactoryCard(context, factory),
                              );
                            },
                          ),
                        ),
                        if (totalPages > 1) _buildPaginationBar(safePage, totalPages),
                      ],
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
                              color: AppColors.error,
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            Text('Gagal memuat: $error'),
                            ElevatedButton(
                              onPressed:
                                  () => ref.invalidate(factoriesListProvider),
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

  // --- PAGINATION BAR ---
  Widget _buildPaginationBar(int currentPage, int totalPages) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: currentPage > 0
                ? () => setState(() => _currentPage = currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            style: IconButton.styleFrom(
              backgroundColor:
                  currentPage > 0 ? AppColors.primary : AppColors.surfaceDark,
              foregroundColor:
                  currentPage > 0 ? AppColors.white : AppColors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Halaman ${currentPage + 1} / $totalPages',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: currentPage < totalPages - 1
                ? () => setState(() => _currentPage = currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            style: IconButton.styleFrom(
              backgroundColor: currentPage < totalPages - 1
                  ? AppColors.primary
                  : AppColors.surfaceDark,
              foregroundColor: currentPage < totalPages - 1
                  ? AppColors.white
                  : AppColors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactoryCard(BuildContext context, FactoryModel factory) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
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
            radius: 30,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: const Icon(
              Icons.factory,
              color: AppColors.primaryDark,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),

          // Name & Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  factory.factoryName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: AppColors.greyDark),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        factory.address,
                        style: const TextStyle(fontSize: 12, color: AppColors.greyDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 14, color: AppColors.greyDark),
                    const SizedBox(width: 4),
                    Text(
                      factory.noTelp,
                      style: const TextStyle(fontSize: 12, color: AppColors.greyDark),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Edit Button
          IconButton(
            onPressed: () => _showFactoryFormDialog(context, factoryToEdit: factory),
            icon: const Icon(Icons.edit_outlined, color: AppColors.white),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.secondary,
            ),
          ),

          const SizedBox(width: 8),

          // Delete Button
          IconButton(
            onPressed: () => _showDeleteConfirmation(context, factory),
            icon: const Icon(Icons.delete_outline, color: AppColors.white),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.error.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  void _showFactoryFormDialog(BuildContext context,
      {FactoryModel? factoryToEdit}) {
    showDialog(
      context: context,
      builder: (context) => FactoryFormDialog(factoryToEdit: factoryToEdit),
    );
  }

  void _showDeleteConfirmation(BuildContext context, FactoryModel factory) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pabrik'),
        content: Text('Yakin ingin menghapus ${factory.factoryName}?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await ref
                    .read(factoryManagementProvider.notifier)
                    .deleteFactory(factory.id);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pabrik berhasil dihapus'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
