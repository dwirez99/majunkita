import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../manage_expeditions/presentations/screens/manage_expeditions_screen.dart';
import '../../../manage_percas/presentations/screens/add_perca_screen.dart';
import '../widgets/dashboard_appbar.dart';
import '../widgets/dashboard_bottom_bar.dart';
import '../widgets/management_menu.dart';
import '../widgets/quick_acces_menu.dart';
import '../widgets/summary_card.dart';
import '../widgets/user_profile_card.dart';
import '../../domain/providers/dashboard_providers.dart';

class DashboarAdminScreen extends ConsumerStatefulWidget {
  const DashboarAdminScreen({super.key});

  @override
  ConsumerState<DashboarAdminScreen> createState() => _DashboarAdminScreenState();
}

class _DashboarAdminScreenState extends ConsumerState<DashboarAdminScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Navigasi ke screen yang sesuai berdasarkan index bottom nav
    switch (index) {
      case 1:
        // Ambil Perca
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddPercaScreen()),
        ).then((_) => setState(() => _selectedIndex = 0));
        break;
      case 3:
        // Pengiriman
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ManageExpeditionsScreen(),
          ),
        ).then((_) => setState(() => _selectedIndex = 0));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DashboardAppBar(title: 'Dashboard Admin'),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
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

              ref
                  .watch(adminDashboardProvider)
                  .when(
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    error:
                        (error, stackTrace) =>
                            Center(child: Text(error.toString())),
                    data: (summary) {
                      return Column(
                        children: [
                          // ── Perca ───────────────────────────────────────
                          SummaryCard(
                            title: '🧵 Perca',
                            children: [
                              _SummaryRow(
                                icon: Icons.warehouse_outlined,
                                label: 'Stok gudang',
                                value: summary.perca.fmtStokGudang,
                              ),
                              _SummaryRow(
                                icon: Icons.people_outline,
                                label: 'Diberikan ke penjahit',
                                value: summary.perca.fmtTotalDiberikan,
                              ),
                              _SummaryRow(
                                icon: Icons.calendar_month_outlined,
                                label: 'Distribusi bulan ini',
                                value: summary.perca.fmtDistribusiBulanIni,
                                isHighlighted: true,
                              ),
                            ],
                          ),

                          // ── Majun ───────────────────────────────────────
                          SummaryCard(
                            title: '🧺 Majun',
                            children: [
                              _SummaryRow(
                                icon: Icons.input_outlined,
                                label: 'Total diterima',
                                value: summary.majun.fmtTotalDiterima,
                              ),
                              _SummaryRow(
                                icon: Icons.local_shipping_outlined,
                                label: 'Total terkirim',
                                value: summary.majun.fmtTotalTerkirim,
                              ),
                              _SummaryRow(
                                icon: Icons.inventory_2_outlined,
                                label: 'Stok tersedia di gudang',
                                value: summary.majun.fmtStokEfektif,
                                isHighlighted: true,
                              ),
                              _SummaryRow(
                                icon: Icons.calendar_month_outlined,
                                label: 'Diterima bulan ini',
                                value: summary.majun.fmtDiterimaBulanIni,
                              ),
                              _SummaryRow(
                                icon: Icons.payments_outlined,
                                label: 'Total upah dibayarkan',
                                value: summary.majun.fmtTotalUpah,
                              ),
                            ],
                          ),

                          // ── Expedisi ────────────────────────────────────
                          SummaryCard(
                            title: '🚚 Expedisi',
                            children: [
                              _SummaryRow(
                                icon: Icons.receipt_long_outlined,
                                label: 'Total pengiriman',
                                value:
                                    '${summary.expedisi.totalPengiriman} kali',
                              ),
                              _SummaryRow(
                                icon: Icons.inventory_outlined,
                                label: 'Total karung dikirim',
                                value:
                                    '${summary.expedisi.totalKarung} karung',
                              ),
                              _SummaryRow(
                                icon: Icons.scale_outlined,
                                label: 'Total berat dikirim',
                                value: summary.expedisi.fmtTotalBerat,
                              ),
                              _SummaryRow(
                                icon: Icons.calendar_month_outlined,
                                label: 'Pengiriman bulan ini',
                                value:
                                    '${summary.expedisi.pengirimanBulanIni} kali',
                                isHighlighted: true,
                              ),
                              _SummaryRow(
                                icon: Icons.monitor_weight_outlined,
                                label: 'Berat bulan ini',
                                value: summary.expedisi.fmtBeratBulanIni,
                              ),
                            ],
                          ),

                          // ── Penjahit ────────────────────────────────────
                          SummaryCard(
                            title: '👗 Penjahit',
                            children: [
                              _SummaryRow(
                                icon: Icons.people_outlined,
                                label: 'Jumlah penjahit terdaftar',
                                value:
                                    '${summary.penjahit.jumlahAktif} orang',
                              ),
                              _SummaryRow(
                                icon: Icons.inventory_2_outlined,
                                label: 'Total stok di penjahit',
                                value: summary.penjahit.fmtTotalStok,
                              ),
                              _SummaryRow(
                                icon: Icons.account_balance_wallet_outlined,
                                label: 'Total saldo belum ditarik',
                                value: summary.penjahit.fmtSaldoBelumDitarik,
                                isHighlighted: true,
                              ),
                            ],
                          ),

                          // ── Limbah ──────────────────────────────────────
                          SummaryCard(
                            title: '♻️ Limbah',
                            children: [
                              _SummaryRow(
                                icon: Icons.delete_outline,
                                label: 'Total diterima',
                                value: summary.limbah.fmtTotalDiterima,
                              ),
                              _SummaryRow(
                                icon: Icons.calendar_month_outlined,
                                label: 'Diterima bulan ini',
                                value: summary.limbah.fmtDiterimaBulanIni,
                                isHighlighted: true,
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: DashboardBottomBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        userRole: 'admin',
      ),
    );
  }
}

// ── Shared row widget for summary cards ──────────────────────────────────────

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
              style: TextStyle(
                fontSize: 13,
                color: AppColors.grey,
              ),
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
