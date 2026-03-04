import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../manage_expeditions/presentations/screens/add_expedition_screen.dart';
import '../../../manage_expeditions/presentations/screens/expedition_history_screen.dart';
import '../../../manage_expeditions/presentations/screens/manage_expedition_partners_screen.dart';
import '../../../manage_expeditions/presentations/screens/manage_expeditions_screen.dart';
import '../../../manage_percas/presentations/screens/add_perca_screen.dart';
import '../../domain/providers/dashboard_providers.dart';
import '../widgets/dashboard_appbar.dart';
import '../widgets/dashboard_bottom_bar.dart';
import '../widgets/summary_card.dart';

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
    setState(() => _selectedIndex = index);
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ExpeditionHistoryScreen(),
        ),
      ).then((_) => setState(() => _selectedIndex = 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final driverSummaryAsync = ref.watch(driverDashboardProvider);

    return Scaffold(
      appBar: const DashboardAppBar(title: 'Dashboard Driver'),
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(driverDashboardProvider);
          ref.invalidate(userProfileProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ── 1. KARTU PROFIL ─────────────────────────────────────
              userProfileAsync.when(
                data: (profile) => _buildProfileCard(
                  name: profile?['nama_lengkap'] ?? 'Driver',
                  role: profile?['role'] ?? 'driver',
                ),
                loading: () => _buildProfileCard(
                    name: 'Memuat...', role: 'driver'),
                error: (_, __) =>
                    _buildProfileCard(name: 'Error', role: 'driver'),
              ),

              const SizedBox(height: 20),

              // ── 2. SAPAAN ────────────────────────────────────────────
              userProfileAsync.when(
                data: (profile) {
                  final firstName =
                      (profile?['nama_lengkap'] as String? ?? 'Driver')
                          .split(' ')
                          .first;
                  return Text(
                    'Hallo, $firstName! 👋',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  );
                },
                loading: () => const Text(
                  'Hallo...',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                error: (_, __) => const Text(
                  'Hallo, Driver!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
              ),

              const SizedBox(height: 4),
              const Text(
                'Apa yang ingin kamu lakukan hari ini?',
                style: TextStyle(fontSize: 13, color: AppColors.grey),
              ),

              const SizedBox(height: 20),

              // ── 3. MENU UTAMA (GRID 2×2) ────────────────────────────
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  _buildMenuCard(
                    icon: Icons.add_box_outlined,
                    title: 'Tambah\nPerca',
                    color: AppColors.accent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AddPercaScreen()),
                    ),
                  ),
                  _buildMenuCard(
                    icon: Icons.local_shipping_outlined,
                    title: 'Tambah\nExpedisi',
                    color: AppColors.primary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AddExpeditionScreen()),
                    ),
                  ),
                  _buildMenuCard(
                    icon: Icons.history_outlined,
                    title: 'Riwayat\nPengiriman',
                    color: AppColors.secondary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ExpeditionHistoryScreen()),
                    ),
                  ),
                  _buildMenuCard(
                    icon: Icons.business_outlined,
                    title: 'Kelola\nExpedisi',
                    color: Colors.indigo,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ManageExpeditionsScreen()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── 4. RINGKASAN PENGIRIMAN ──────────────────────────────
              const Text(
                'Ringkasan Pengirimanku',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 12),

              driverSummaryAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                error: (error, _) => _buildErrorCard(error.toString()),
                data: (summary) => SummaryCard(
                  title: '🚚 Expedisi Saya',
                  children: [
                    _SummaryRow(
                      icon: Icons.receipt_long_outlined,
                      label: 'Total pengiriman',
                      value: '${summary['total_pengiriman']} kali',
                    ),
                    _SummaryRow(
                      icon: Icons.inventory_outlined,
                      label: 'Total karung dikirim',
                      value: '${summary['total_karung']} karung',
                    ),
                    _SummaryRow(
                      icon: Icons.scale_outlined,
                      label: 'Total berat dikirim',
                      value: summary['fmt_total_berat'] as String,
                    ),
                    _SummaryRow(
                      icon: Icons.calendar_month_outlined,
                      label: 'Pengiriman bulan ini',
                      value: '${summary['pengiriman_bulan_ini']} kali',
                      isHighlighted: true,
                    ),
                    _SummaryRow(
                      icon: Icons.monitor_weight_outlined,
                      label: 'Berat bulan ini',
                      value: summary['fmt_berat_bulan_ini'] as String,
                      isHighlighted: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── 5. MITRA EXPEDISI SHORTCUT ───────────────────────────
              _buildShortcutBanner(
                icon: Icons.business_center_outlined,
                label: 'Kelola Mitra Expedisi',
                subtitle: 'Tambah atau ubah perusahaan jasa pengiriman',
                color: Colors.indigo,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const ManageExpeditionPartnersScreen()),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: DashboardBottomBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        userRole: 'driver',
      ),
    );
  }

  // ── Widget Builders ────────────────────────────────────────────────────

  Widget _buildProfileCard(
      {required String name, required String role}) {
    final roleLabel =
        role.isNotEmpty ? '${role[0].toUpperCase()}${role.substring(1)}' : role;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: AppColors.white, size: 34),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    roleLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.local_shipping,
              color: AppColors.white, size: 36),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutBanner({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary Row Widget ──────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isHighlighted;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isHighlighted ? AppColors.secondary : AppColors.greyDark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.grey),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  isHighlighted ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

