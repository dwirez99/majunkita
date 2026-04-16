import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../data/models/tailor_model.dart';
import '../../domain/providers/tailor_provider.dart';
import 'tailor_detail_screen.dart';
import 'tailor_form_dialog.dart';

/// Screen untuk menampilkan daftar tailor (penjahit)
class TailorsListScreen extends ConsumerStatefulWidget {
  const TailorsListScreen({super.key});

  @override
  ConsumerState<TailorsListScreen> createState() => _TailorsListScreenState();
}

class _TailorsListScreenState extends ConsumerState<TailorsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Format berat stok: bilangan bulat tanpa desimal, non-integer dengan 1
  /// desimal. Gunakan [truncateToDouble] untuk deteksi bulat yang aman dari
  /// ketidakstabilan floating-point.
  String _fmtStock(double value) {
    if (value == value.truncateToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final tailorsAsync = ref.watch(tailorsListProvider);
    final actionState = ref.watch(tailorManagementProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    final isAdmin = userProfileAsync.when(
      data:
          (profile) =>
              (profile?['role']?.toString().toLowerCase() ?? '') == 'admin',
      loading: () => false,
      error: (_, __) => false,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Kelola Penjahit',
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
              // --- TOMBOL TAMBAH  ---
              if (isAdmin) ...[
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed:
                        actionState.isLoading
                            ? null // Disable kalau lagi loading delete/create
                            : () => _showAddTailorDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[400],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Tambah Penjahit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

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
                    // Tombol Clear Search (Opsional UX improvement)
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
                          child: _buildTailorCard(context, tailor),
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

  Widget _buildTailorCard(BuildContext context, TailorModel tailor) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TailorDetailScreen(initialTailor: tailor),
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
            // Avatar - Show image if available, otherwise show initial
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
                    tailor.noTelp,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  if (tailor.totalStock > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          tailor.totalStock > 5
                              ? Icons.warning_amber_rounded
                              : Icons.home_outlined,
                          color:
                              tailor.totalStock > 5
                                  ? Colors.amber[300]
                                  : Colors.white70,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Sisa: ${_fmtStock(tailor.totalStock)} Kg',
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                tailor.totalStock > 5
                                    ? Colors.amber[300]
                                    : Colors.white70,
                            fontWeight:
                                tailor.totalStock > 5
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Delete Button
            IconButton(
              onPressed: () => _showDeleteConfirmation(context, tailor),
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.withValues(
                  alpha: 0.8,
                ), // Merah biar kelihatan bahaya
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- DIALOG FUNCTIONS (INTEGRATED) ---

  void _showAddTailorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const TailorFormDialog(),
    );
  }

  void _showDeleteConfirmation(BuildContext context, TailorModel tailor) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hapus Penjahit'),
            content: Text('Yakin ingin menghapus penjahit ${tailor.name}?'),
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
                  Navigator.pop(context); // Tutup dialog konfirmasi

                  // Panggil Provider Delete
                  try {
                    await ref
                        .read(tailorManagementProvider.notifier)
                        .deleteTailor(tailor.id);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Penjahit berhasil dihapus'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // Refresh the list
                      ref.invalidate(tailorsListProvider);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal hapus: $e'),
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
