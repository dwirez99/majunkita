import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../manage_expeditions/presentations/screens/expedition_history_screen.dart';
import '../../../manage_partner/presentations/screens/manage_partner_screen.dart';
import '../../../manage_percas/presentations/screens/add_perca_history_screen.dart';
import '../widgets/dashboard_appbar.dart';
import '../widgets/dashboard_bottom_bar.dart';
import '../widgets/user_profile_card.dart';

class DashboardManagerScreen extends ConsumerStatefulWidget {
  const DashboardManagerScreen({super.key});

  @override
  ConsumerState<DashboardManagerScreen> createState() =>
      _DashboardManagerScreenState();
}

class _DashboardManagerScreenState
    extends ConsumerState<DashboardManagerScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Navigasi ke screen yang sesuai berdasarkan index bottom nav
    switch (index) {
      case 1:
        // Riwayat Perca
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddPercaHistoryScreen(),
          ),
        ).then((_) => setState(() => _selectedIndex = 0));
        break;
      case 2:
        // Riwayat Pengiriman
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ExpeditionHistoryScreen(),
          ),
        ).then((_) => setState(() => _selectedIndex = 0));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Ambil data profil dari Riverpod (agar nama dinamis)
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: const DashboardAppBar(title: 'Dashboard Manager'),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 2. PROFILE CARD (Shared Editable Card)
              const UserProfileCard(),

              const SizedBox(height: 24),

              // 3. GREETING TEXT
              userProfileAsync.when(
                data: (profile) {
                  final rawName =
                      (profile?['name'] ??
                              profile?['nama_lengkap'] ??
                              'Manager')
                          .toString();
                  final firstName =
                      rawName.trim().isEmpty
                          ? 'Manager'
                          : rawName.trim().split(' ').first;
                  return Text(
                    'Hallo, $firstName!',
                    style: AppTextStyles.heading3,
                  );
                },
                loading:
                    () => const Text('Hallo...', style: AppTextStyles.heading3),
                error:
                    (_, _) =>
                        const Text('Hallo!', style: AppTextStyles.heading3),
              ),

              const SizedBox(height: 20),

              // 4. CARD RENCANA PENGIRIMAN TERBARU
              _buildShipmentCard(),

              const SizedBox(height: 30),

              // 5. ACTION BUTTONS (Menu Utama)
              _buildMenuButton(
                label: 'RIWAYAT AMBIL DAN SETOR\nPERCA',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddPercaHistoryScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              _buildMenuButton(
                label: 'RIWAYAT PENGIRIMAN',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ExpeditionHistoryScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              _buildMenuButton(
                label: 'MANAJEMEN PARTNER',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManagePartnerScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),

      // 6. BOTTOM NAVIGATION BAR
      bottomNavigationBar: DashboardBottomBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        userRole: 'manager',
      ),
    );
  }

  // --- WIDGET BUILDERS (Agar kode rapi) ---

  Widget _buildShipmentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border.all(color: AppColors.cardBorder, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rencana Pengiriman Terbaru',
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment:
                CrossAxisAlignment.end, // Agar button sejajar bawah
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
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ExpeditionHistoryScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Detail Pengiriman',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.white,
                    ),
                  ),
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
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 2,
          shadowColor: AppColors.primary.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.buttonText.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w800,
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
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.greyDark,
            ),
          ),
        ),
        const Text(
          ':  ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.greyDark,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 12,
            color: AppColors.black,
          ),
        ),
      ],
    );
  }
}
