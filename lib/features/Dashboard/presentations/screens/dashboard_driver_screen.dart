import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../widgets/dashboard_appbar.dart';
import '../widgets/dashboard_bottom_bar.dart';

class DashboardDriverScreen extends ConsumerStatefulWidget {
  const DashboardDriverScreen({super.key});

  @override
  ConsumerState<DashboardDriverScreen> createState() =>
      _DashboardDriverScreenState();
}

class _DashboardDriverScreenState
    extends ConsumerState<DashboardDriverScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Ambil data profil dari Riverpod (agar nama dinamis)
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: const DashboardAppBar(title: 'Dashboard Driver'),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 2. PROFILE CARD
              userProfileAsync.when(
                data:
                    (profile) => _buildProfileCard(
                      name: profile?['nama_lengkap'] ?? 'Driver',
                      role: profile?['role'] ?? 'Driver',
                    ),
                loading:
                    () => _buildProfileCard(name: 'Loading...', role: '...'),
                error:
                    (err, _) =>
                        _buildProfileCard(name: 'Error', role: 'Offline'),
              ),

              const SizedBox(height: 24),

              // 3. GREETING TEXT
              userProfileAsync.when(
                data:
                    (profile) => Text(
                      'Hallo, ${profile?['nama_lengkap']?.split(' ')[0] ?? 'Driver'}!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                loading:
                    () => const Text(
                      'Hallo...',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                error:
                    (_, __) => const Text(
                      'Hallo!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              ),

              const SizedBox(height: 20),

              // 4. DRIVER ACTION BUTTONS (Menu Utama)
              _buildMenuButton(
                label: 'TAMBAH STOK PERCA',
                onTap: () {
                  // TODO: Navigasi ke Tambah Stok Perca
                },
              ),
              const SizedBox(height: 16),

              _buildMenuButton(
                label: 'TAMBAH MAJUN SIAP KIRIM',
                onTap: () {
                  // TODO: Navigasi ke Tambah Majun Siap Kirim
                },
              ),
              const SizedBox(height: 16),

              _buildMenuButton(
                label: 'RENCANA PENGIRIMAN',
                onTap: () {
                  // TODO: Navigasi ke Rencana Pengiriman
                },
              ),
              const SizedBox(height: 16),

              _buildMenuButton(
                label: 'RIWAYAT PENGIRIMAN',
                onTap: () {
                  // TODO: Navigasi ke Riwayat Pengiriman
                },
              ),
            ],
          ),
        ),
      ),

      // 5. BOTTOM NAVIGATION BAR
      bottomNavigationBar: DashboardBottomBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        userRole: 'driver',
      ),
    );
  }

  // --- WIDGET BUILDERS (Agar kode rapi) ---

  Widget _buildProfileCard({required String name, required String role}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.lightGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Icon Avatar Bulat Hitam
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.black,
            child: Icon(Icons.person, color: Colors.white, size: 40),
          ),
          const SizedBox(width: 16),
          // Kolom Nama & Role
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                // Capitalize first letter
                role.isNotEmpty
                    ? "${role[0].toUpperCase()}${role.substring(1)}"
                    : role,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 70, // Tinggi tombol besar
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[400], // Warna hijau cerah
          foregroundColor: Colors.white, // Warna teks putih
          elevation: 2, // Sedikit shadow untuk depth
          shadowColor: Colors.green.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900, // Extra Bold
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
