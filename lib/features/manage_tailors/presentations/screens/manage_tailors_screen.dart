import 'package:flutter/material.dart';
import 'tailors_list_screen.dart';

/// Screen untuk menampilkan kategori manajemen penjahit
/// Similar to ManagePartnerScreen
class ManageTailorsScreen extends StatelessWidget {
  const ManageTailorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Manajemen Penjahit',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.grey[200],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.grey),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Kategori Penjahit',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              // Daftar Penjahit Card
              _buildTailorCard(
                context: context,
                icon: Icons.people,
                title: 'Daftar Penjahit',
                description: 'Lihat dan kelola data semua penjahit',
                color: Colors.blue[400]!,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TailorsListScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Statistik Penjahit Card
              _buildTailorCard(
                context: context,
                icon: Icons.bar_chart,
                title: 'Statistik Penjahit',
                description: 'Lihat statistik dan performa penjahit',
                color: Colors.orange[400]!,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur statistik akan segera hadir'),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Laporan Penjahit Card
              _buildTailorCard(
                context: context,
                icon: Icons.description,
                title: 'Laporan Penjahit',
                description: 'Lihat laporan aktivitas penjahit',
                color: Colors.purple[400]!,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur laporan akan segera hadir'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTailorCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
