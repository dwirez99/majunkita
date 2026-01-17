import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/management_menu.dart';
import '../widgets/quick_acces_menu.dart';
import '../widgets/summary_card.dart';
import '../widgets/user_profile_card.dart';
import '../../domain/providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      // Kita gunakan AppBar transparan agar konten bisa dimulai dari atas
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color.fromARGB(239, 14, 255, 175),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // 1. KARTU PROFIL PENGGUNA
              const UserProfileCard(),

              const SizedBox(height: 24),

              // 2. TEKS SAPAAN
              const Text(
                'Hallo, Doni!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              // 3. AKSES CEPAT
              const QuickAccessButtons(),

              const SizedBox(height: 24),

              // 4. MENU KELOLA
              const ManagementMenuGrid(),

              const SizedBox(height: 24),

              // 5. BAGIAN RINGKASAN
              const Text(
                'Ringkasan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              ref
                  .watch(adminDashboardProvider)
                  .when(
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    error:
                        (error, stackTrace) =>
                            Center(child: Text(error.toString())),
                    data: (summary) {
                      // 'summary' adalah objek AdminDashboardSummary yang sudah terisi data!
                      return Column(
                        children: [
                          SummaryCard(
                            title: 'Ringkasan Perca',
                            children: [
                              Text(
                                'Stok Perca Saat Ini : ${summary.percaSummary.stockSaatIni} KG',
                              ),
                              Text(
                                'Stok pada penjahit : ${summary.stockAtTailor} KG',
                              ),
                              // Tambahkan data lain jika ada
                            ],
                          ),
                          SummaryCard(
                            title: 'Ringkasan Majun',
                            children: [
                              Text(
                                'Stok majun Saat Ini : ${summary.majunSummary.stockSaatIni} KG',
                              ),
                              // Tambahkan data lain jika ada
                            ],
                          ),
                          SummaryCard(
                            title: 'Ringkasan Penjahit',
                            children: [
                              Text(
                                'Jumlah Penjahit Aktif : ${summary.tailorSummary.jumlahAktif}',
                              ),
                              Text(
                                'Upah belum dibayarkan : ${summary.tailorSummary.formattedUnpaidWages}',
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // Method to show logout confirmation dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                await Supabase.instance.client.auth.signOut();
                // Navigation will be handled automatically by AuthWrapper's listener
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
