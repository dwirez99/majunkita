import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class DashboardBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String userRole;

  const DashboardBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.userRole,
  });

  List<BottomNavigationBarItem> _getNavigationItems() {
    if (userRole == 'admin') {
      return const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home, size: 30),
          label: 'Menu Awal',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2, size: 30),
          label: 'Ambil Perca',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_shipping, size: 30),
          label: 'Ambil Majun',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.delivery_dining, size: 30),
          label: 'Pengiriman',
        ),
      ];
    } else if (userRole == 'manager') {
      return const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home, size: 30),
          label: 'Menu Awal',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long, size: 30),
          label: 'Riwayat Perca',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history, size: 30),
          label: 'Riwayat Pengiriman',
        ),
      ];
    }
    // Default fallback for driver role
    return const <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: Icon(Icons.home, size: 30),
        label: 'Menu Awal',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.receipt, size: 30),
        label: 'Riwayat',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.grey,
      backgroundColor: AppColors.white,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      items: _getNavigationItems(),
    );
  }
}
