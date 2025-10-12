import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/management_menu.dart';
import '../widgets/quick_acces_menu.dart';
import '../widgets/summary_card.dart';
import '../widgets/user_profile_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      // Kita gunakan AppBar transparan agar konten bisa dimulai dari atas
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SummaryCard(
                title: 'Ringkasan Perca',
                children: [
                  Text('Stok Perca Saat Ini : 580 KG'),
                  Text('Stok yang ada pada penjahit : 60kg'),
                  Text('Terakhir Ambil : 29-05-2025'),
                ],
              ),
               const SummaryCard(
                title: 'Ringkasan Majun',
                children: [
                  Text('Stok majun Saat Ini : 120 KG'),
                  Text('Kemungkinan kirim : 20 Karung'),
                  Text('Pengiriman Terakhir : 01-09-2024'),
                ],
              ),
              const SummaryCard(
                title: 'Ringkasan Penjahit',
                children: [
                  Text('Jumlah Penjahit Aktif : 10'),
                  Text('Upah yang belum dibayarkan : Rp.700,000.00'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}