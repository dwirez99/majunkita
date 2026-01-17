import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/providers/auth_provider.dart';

class DashboardManagerScreen extends ConsumerStatefulWidget {
  const DashboardManagerScreen({super.key});

  @override
  ConsumerState<DashboardManagerScreen> createState() => _DashboardManagerScreenState();
}

class _DashboardManagerScreenState extends ConsumerState<DashboardManagerScreen> {
  // Index untuk Bottom Navigation Bar
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // TODO: Tambahkan logika navigasi halaman di sini jika diperlukan
  }

  @override
  Widget build(BuildContext context) {
    // 1. Ambil data profil dari Riverpod (agar nama dinamis)
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 2. PROFILE CARD (Kotak Abu di Atas)
              userProfileAsync.when(
                data: (profile) => _buildProfileCard(
                  name: profile?['nama'] ?? 'Doni Setiawan',
                  role: profile?['role'] ?? 'Manager',
                ),
                loading: () => _buildProfileCard(name: 'Loading...', role: '...'),
                error: (err, _) => _buildProfileCard(name: 'Error', role: 'Offline'),
              ),

              const SizedBox(height: 24),

              // 3. GREETING TEXT
              userProfileAsync.when(
                data: (profile) => Text(
                  'Hallo, ${profile?['nama']?.split(' ')[0] ?? 'Doni'}!',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                loading: () => const Text('Hallo...', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                error: (_, __) => const Text('Hallo!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 20),

              // 4. CARD RENCANA PENGIRIMAN TERBARU
              _buildShipmentCard(),

              const SizedBox(height: 30),

              // 5. ACTION BUTTONS (Menu Utama)
              _buildMenuButton(
                label: 'RIWAYAT AMBIL DAN SETOR\nPERCA',
                onTap: () {
                  // TODO: Navigasi ke Riwayat Perca
                },
              ),
              const SizedBox(height: 16),
              
              _buildMenuButton(
                label: 'RIWAYAT PENGIRIMAN',
                onTap: () {
                  // TODO: Navigasi ke Riwayat Pengiriman
                },
              ),
              const SizedBox(height: 16),
              
              _buildMenuButton(
                label: 'MANAJEMEN PARTNER',
                onTap: () {
                  // TODO: Navigasi ke Kelola Partner
                },
              ),
            ],
          ),
        ),
      ),
      
      // 6. BOTTOM NAVIGATION BAR
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        backgroundColor: Colors.grey[300], // Sesuai warna footer di desain
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 30),
            label: 'Menu Awal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long, size: 30), // Ikon mirip struk/kuitansi
            label: 'Riwayat Perca',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history, size: 30),
            label: 'Riwayat Pengiriman',
          ),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS (Agar kode rapi) ---

  Widget _buildProfileCard({required String name, required String role}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0), // Abu-abu muda
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
                  color: Colors.black,
                ),
              ),
              Text(
                // Capitalize first letter
                role.isNotEmpty ? "${role[0].toUpperCase()}${role.substring(1)}" : role,
                style: const TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0), // Abu-abu muda
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rencana Pengiriman Terbaru',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end, // Agar button sejajar bawah
            children: [
              // Kolom Informasi Data
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: 'Tanggal Kirim', value: '19 04 2025'),
                  SizedBox(height: 4),
                  _InfoRow(label: 'Jumlah Kirim', value: '23 Karung'),
                  SizedBox(height: 4),
                  _InfoRow(label: 'Bobot Kirim', value: '1150 KG'),
                ],
              ),
              
              // Tombol Detail Kecil
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[300], // Abu lebih gelap sedikit
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Detail Pengiriman',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({required String label, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 70, // Tinggi tombol besar
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF0F0F0), // Abu-abu muda
          foregroundColor: Colors.black, // Warna teks
          elevation: 0, // Flat design sesuai gambar
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
          ),
        ),
      ),
    );
  }
}

// Widget Helper Kecil untuk Baris Info (Tanggal : Nilai)
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100, // Lebar label tetap agar titik dua sejajar
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        const Text(':  ', style: TextStyle(fontWeight: FontWeight.w600)),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
        ),
      ],
    );
  }
}