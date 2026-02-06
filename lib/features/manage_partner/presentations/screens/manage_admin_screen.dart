import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Sesuaikan import ini dengan struktur foldermu
import '../../domain/providers/manage_partner_providers.dart';
import '../../data/models/manage_partner_models.dart'; // Import Model KaryawanAdmin
import '../widgets/staff_form_dialog.dart'; // Import Dialog Generic baru

class ManageAdminScreen extends ConsumerStatefulWidget {
  const ManageAdminScreen({super.key});

  @override
  ConsumerState<ManageAdminScreen> createState() => _ManageAdminScreenState();
}

class _ManageAdminScreenState extends ConsumerState<ManageAdminScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Watch Provider List Admin yang baru (sudah auto-search)
    final adminsState = ref.watch(adminsListProvider);

    // 2. Watch Provider Action (untuk loading state saat delete)
    final actionState = ref.watch(staffManagementProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Kelola Partner Admin',
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
              // --- TOMBOL TAMBAH ---
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed:
                      actionState.isLoading
                          ? null // Disable kalau lagi loading delete/create
                          : () => _showAddAdminDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[400],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Tambah Partner Admin',
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
                          hintText: 'Cari nama admin...',
                        ),
                        onChanged: (value) {
                          // Update Query di Provider
                          ref
                              .read(adminSearchQueryProvider.notifier)
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
                          ref.read(adminSearchQueryProvider.notifier).clear();
                        },
                      )
                    else
                      const Icon(Icons.search, color: Colors.grey),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // --- TOMBOL REFRESH ---Gagal
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    // Paksa refresh data
                    ref.invalidate(adminsListProvider);
                  },
                  icon: const Icon(Icons.refresh, color: Colors.black),
                  label: const Text(
                    'Refresh Data', // Ganti "Terbaru" jadi Refresh karena logic sort default database
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
                child: adminsState.when(
                  data: (admins) {
                    if (admins.isEmpty) {
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
                                  ? 'Belum ada data Admin.'
                                  : 'Admin "${_searchController.text}" tidak ditemukan.',
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
                      itemCount: admins.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final admin = admins[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildAdminCard(context, admin),
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
                                  () => ref.invalidate(adminsListProvider),
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

  Widget _buildAdminCard(BuildContext context, KaryawanAdmin admin) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[400],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
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
            child: Text(
              admin.nama.isNotEmpty ? admin.nama[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  admin.nama,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  admin.noTelp,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),

          // Edit Button
          IconButton(
            onPressed: () => _showEditAdminDialog(context, admin),
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withOpacity(0.1),
            ),
          ),

          const SizedBox(width: 8),

          // Delete Button
          IconButton(
            onPressed: () => _showDeleteConfirmation(context, admin),
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(
                0.8,
              ), // Merah biar kelihatan bahaya
            ),
          ),
        ],
      ),
    );
  }

  // --- DIALOG FUNCTIONS (INTEGRATED) ---

  void _showAddAdminDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => const StaffFormDialog(
            role: AppRoles.admin, // Pass Role Constant
          ),
    );
  }

  void _showEditAdminDialog(BuildContext context, KaryawanAdmin admin) {
    showDialog(
      context: context,
      builder:
          (context) => StaffFormDialog(
            role: AppRoles.admin,
            staffToEdit:
                admin, // Langsung lempar object admin, GAK PERLU Provider Selection
          ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, KaryawanAdmin admin) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hapus Admin'),
            content: Text('Yakin ingin menghapus akses untuk ${admin.nama}?'),
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

                  // Panggil Provider Delete yang baru
                  try {
                    await ref
                        .read(staffManagementProvider.notifier)
                        .deleteStaff(id: admin.id, role: AppRoles.admin);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Admin berhasil dihapus'),
                          backgroundColor: Colors.green,
                        ),
                      );
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
