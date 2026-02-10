// lib/features/dashboard/presentation/widgets/management_menu_grid.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../manage_tailors/presentations/screens/tailors_list_screen.dart';

class ManagementMenuGrid extends StatelessWidget {
  const ManagementMenuGrid({super.key});

  @override
  Widget build(BuildContext context) {
    // Daftar menu bisa dibuat dinamis nanti
    final List<Map<String, dynamic>> menuItems = [
      {
        'label': 'Kelola\nStok Perca',
        'color': AppColors.primary,
        'icon': Icons.inventory_2,
      },
      {
        'label': 'Kelola\nStok Majun',
        'color': AppColors.secondary,
        'icon': Icons.shopping_bag,
      },
      {
        'label': 'Kelola\nPenjahit',
        'color': AppColors.accent,
        'icon': Icons.person_2,
      },
      {
        'label': 'Kelola\nPengiriman',
        'color': AppColors.primaryDark,
        'icon': Icons.local_shipping,
      },
      {
        'label': 'Kelola\nPartner',
        'color': AppColors.secondaryDark,
        'icon': Icons.handshake,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menu Kelola',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 12),
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
            final item = menuItems[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.cardBorder, width: 1),
              ),
              color: AppColors.cardBackground,
              child: InkWell(
                onTap: () {
                  _handleMenuTap(context, index);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        (item['color'] as Color).withValues(alpha: 0.1),
                        (item['color'] as Color).withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        size: 32,
                        color: item['color'] as Color,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['label'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _handleMenuTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        // TODO: Navigate to Kelola Stok Perca
        break;
      case 1:
        // TODO: Navigate to Kelola Stok Majun
        break;
      case 2:
        // Navigate to Kelola Penjahit
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TailorsListScreen()),
        );
        break;
      case 3:
        // TODO: Navigate to Kelola Pengiriman
        break;
      case 4:
        // TODO: Navigate to Kelola Partner
        break;
      default:
        break;
    }
  }
}