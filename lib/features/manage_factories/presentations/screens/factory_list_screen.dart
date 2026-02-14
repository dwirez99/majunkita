import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final factoriesAsync = ref.watch(factoriesListProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Kelola Data Pabrik',
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
              // --- TOMBOL TAMBAH PABRIK ---
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () => _showFactoryFormDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
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
                          hintText: 'Cari nama pabrik...',
                        ),
                        onChanged: (value) {
                          ref
                              .read(factorySearchQueryProvider.notifier)
                              .setQuery(value);
                        },
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(factorySearchQueryProvider.notifier)
                              .clear();
                        },
                      )
                    else
                      const Icon(Icons.search, color: Colors.grey),
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
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'Belum ada data Pabrik.'
                                  : 'Pabrik "${_searchController.text}" tidak ditemukan.',
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
                      itemCount: factories.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final factory = factories[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildFactoryCard(context, factory),
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

  Widget _buildFactoryCard(BuildContext context, FactoryModel factory) {
    return Container(
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
            radius: 30,
            backgroundColor: Colors.white,
            child: const Icon(
              Icons.factory,
              color: Colors.green,
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
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        factory.address,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      factory.noTelp,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Edit Button
          IconButton(
            onPressed: () => _showFactoryFormDialog(context, factoryToEdit: factory),
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.1),
            ),
          ),

          const SizedBox(width: 8),

          // Delete Button
          IconButton(
            onPressed: () => _showDeleteConfirmation(context, factory),
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: 0.8),
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
              style: TextStyle(color: Colors.grey),
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
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
