// lib/features/dashboard/presentation/widgets/management_menu_grid.dart
import 'package:flutter/material.dart';

class ManagementMenuGrid extends StatelessWidget {
  const ManagementMenuGrid({super.key});

  @override
  Widget build(BuildContext context) {
    // Daftar menu bisa dibuat dinamis nanti
    final List<String> menuItems = [
      'Kelola\nStok Perca', 'Kelola\nStok Majun',
      'Kelola\nPenjahit', 'Kelola\nPengiriman',
      'Kelola\nPartner',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Menu Kelola', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true, // Penting di dalam SingleChildScrollView
          physics: const NeverScrollableScrollPhysics(), // Nonaktifkan scroll internal GridView
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 kolom
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5, // Atur rasio lebar:tinggi card
          ),
          itemCount: menuItems.length,
          itemBuilder: (context, index) {
            return Card(
              child: InkWell(
                onTap: () {
                  // TODO: Tambahkan navigasi sesuai menu
                },
                child: Center(
                  child: Text(
                    menuItems[index],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}