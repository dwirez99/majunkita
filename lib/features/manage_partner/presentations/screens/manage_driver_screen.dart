import '../../../../core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Sesuaikan path import ini
import '../../domain/providers/manage_partner_providers.dart';
import '../../data/models/manage_partner_models.dart'; // Import Model Driver
import '../widgets/staff_form_dialog.dart'; // Import Dialog Generic

class ManageDriverScreen extends ConsumerStatefulWidget {
  const ManageDriverScreen({super.key});

  @override
  ConsumerState<ManageDriverScreen> createState() => _ManageDriverScreenState();
}

class _ManageDriverScreenState extends ConsumerState<ManageDriverScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Watch Provider List Driver yang baru (Auto-Search enabled)
    final driversState = ref.watch(driversListProvider);

    // 2. Watch Provider Action (untuk loading state saat create/delete)
    final actionState = ref.watch(staffManagementProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Kelola Driver',
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
              // --- TOMBOL TAMBAH DRIVER ---
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed:
                      actionState.isLoading
                          ? null
                          : () => _showAddDriverDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, // Hijau lebih tua dikit
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Tambah Driver Armada',
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
                          hintText: 'Cari nama driver...',
                        ),
                        onChanged: (value) {
                          // Update Query khusus Driver
                          ref
                              .read(driverSearchQueryProvider.notifier)
                              .setQuery(value);
                        },
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.grey),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(driverSearchQueryProvider.notifier).clear();
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
                    // Refresh data driver
                    ref.invalidate(driversListProvider);
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

              // --- DRIVER LIST ---
              Expanded(
                child: driversState.when(
                  data: (drivers) {
                    if (drivers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.local_shipping_outlined,
                              size: 60,
                              color: AppColors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'Belum ada data Driver.'
                                  : 'Driver "${_searchController.text}" tidak ditemukan.',
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: drivers.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final driver = drivers[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildDriverCard(context, driver),
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
                              color: AppColors.error,
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            Text('Gagal memuat: $error'),
                            ElevatedButton(
                              onPressed:
                                  () => ref.invalidate(driversListProvider),
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

  Widget _buildDriverCard(BuildContext context, Driver driver) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(12),
        // Tambahkan shadow sedikit biar elegan
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
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
              Icons.drive_eta,
              color: AppColors.primaryDark,
              size: 30,
            ), // Icon Mobil/Driver
          ),
          const SizedBox(width: 16),

          // Name & Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                // Tampilkan No Telp atau Email sebagai sub-info
                Row(
                  children: [
                    const Icon(Icons.phone, size: 14, color: AppColors.greyDark),
                    const SizedBox(width: 4),
                    Text(
                      driver.noTelp,
                      style: const TextStyle(fontSize: 12, color: AppColors.greyDark),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Edit Button
          IconButton(
            onPressed: () => _showEditDriverDialog(context, driver),
            icon: const Icon(Icons.edit_outlined, color: AppColors.white),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.secondary,
            ),
          ),

          const SizedBox(width: 8),

          // Delete Button
          IconButton(
            onPressed: () => _showDeleteConfirmation(context, driver),
            icon: const Icon(Icons.delete_outline, color: AppColors.white),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.error.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  // --- DIALOG FUNCTIONS ---

  void _showAddDriverDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => const StaffFormDialog(
            role: AppRoles.driver, // KUNCI: Set Role jadi Driver
          ),
    );
  }

  void _showEditDriverDialog(BuildContext context, Driver driver) {
    showDialog(
      context: context,
      builder:
          (context) => StaffFormDialog(
            role: AppRoles.driver,
            staffToEdit: driver, // Lempar object driver langsung
          ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Driver driver) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hapus Driver'),
            content: Text('Yakin ingin menghapus ${driver.name}?'),
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
                    // Panggil Single Provider untuk delete
                    await ref
                        .read(staffManagementProvider.notifier)
                        .deleteStaff(
                          id: driver.id,
                          role: AppRoles.driver, // Beritahu provider ini Driver
                        );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Driver berhasil dihapus'),
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
