import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../manage_expeditions/presentations/screens/expedition_history_screen.dart';
import '../../../manage_expeditions/domain/expedition_provider.dart';
import '../../../manage_expeditions/data/models/expedition_model.dart';
import '../../../manage_partner/presentations/screens/manage_partner_screen.dart';
import '../../../manage_percas/presentations/screens/add_perca_history_screen.dart';
import '../../../manage_notifications/presentations/screens/admin_notifications_screen.dart';
import '../../../manage_notifications/domain/providers/wa_notifications_provider.dart';
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
    final expeditionsAsync = ref.watch(expeditionListProvider);
    final badgeCount = ref
        .watch(waNotificationsBadgeCountProvider)
        .maybeWhen(data: (value) => value, orElse: () => 0);

    return Scaffold(
      appBar: DashboardAppBar(
        title: 'Dashboard Manager',
        showNotifications: true,
        userRole: 'manager',
        notificationBadgeCount: badgeCount,
        onNotificationsTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminNotificationsScreen()),
          );
        },
      ),
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
              _buildShipmentCard(expeditionsAsync),

              const SizedBox(height: 30),

              // 5. ACTION BUTTONS (Menu Utama)
              _buildMenuButton(
                label: 'RIWAYAT AMBIL DAN SETOR\nPERCA',
                backgroundColor: AppColors.secondary,
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
                backgroundColor: AppColors.accent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              const ExpeditionHistoryScreen(openLatestOnLoad: true),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              _buildMenuButton(
                label: 'MANAJEMEN PARTNER',
                backgroundColor: AppColors.primaryDark,
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

  Widget _buildShipmentCard(AsyncValue<List<ExpeditionModel>> expeditionsAsync) {
    final dateFormatter = DateFormat('dd MMM yyyy');

    String formatWeight(num value) {
      if (value % 1 == 0) return value.toInt().toString();
      return value.toStringAsFixed(1);
    }

    Widget buildCardContent({
      required String date,
      required String sacks,
      required String weight,
    }) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(label: 'Tanggal Kirim', value: date),
              const SizedBox(height: 4),
              _InfoRow(label: 'Jumlah Kirim', value: sacks),
              const SizedBox(height: 4),
              _InfoRow(label: 'Bobot Kirim', value: weight),
            ],
          ),

          // Tombol Detail Kecil
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          const ExpeditionHistoryScreen(openLatestOnLoad: true),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.secondaryDark,
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
      );
    }

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
            'Pengiriman Terbaru',
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: 12),
          expeditionsAsync.when(
            loading:
                () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(color: AppColors.primary),
                ),
            error:
                (error, _) => Text(
                  'Gagal memuat pengiriman terbaru',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            data: (expeditions) {
              if (expeditions.isEmpty) {
                return Text(
                  'Belum ada data pengiriman.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.greyDark,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }

              final latest = expeditions.first;
              return buildCardContent(
                date: dateFormatter.format(latest.expeditionDate),
                sacks: '${latest.sackNumber} Karung',
                weight: '${formatWeight(latest.totalWeight)} KG',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required String label,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 70, // Tinggi tombol besar
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: AppColors.white,
          elevation: 2,
          shadowColor: backgroundColor.withValues(alpha: 0.35),
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
