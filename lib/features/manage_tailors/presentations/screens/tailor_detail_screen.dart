import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/tailor_model.dart';
import '../../domain/providers/tailor_provider.dart';
import 'tailor_form_dialog.dart';

/// Screen detail penjahit.
///
/// Menampilkan:
///  - Informasi profil penjahit (selalu segar: di-fetch via [tailorByIdProvider])
///  - Estimasi Sisa Perca di Rumah (= total_stock dari DB)
///  - Rasio Efisiensi Personal (Reff)
///  - Prediksi Produksi Majun dari sisa perca
///
/// Setelah dialog edit ditutup, layar invalidate kedua provider sehingga
/// nama/telepon/alamat/foto langsung diperbarui tanpa keluar-masuk.
class TailorDetailScreen extends ConsumerStatefulWidget {
  /// Tailor awal — dipakai sebagai fallback saat provider masih loading.
  final TailorModel initialTailor;

  const TailorDetailScreen({super.key, required this.initialTailor});

  @override
  ConsumerState<TailorDetailScreen> createState() => _TailorDetailScreenState();
}

class _TailorDetailScreenState extends ConsumerState<TailorDetailScreen> {
  /// Buka dialog edit, lalu invalidate provider agar data diperbarui.
  Future<void> _openEditDialog(TailorModel current) async {
    await showDialog<void>(
      context: context,
      builder: (_) => TailorFormDialog(tailorToEdit: current),
    );
    // Dialog sudah ditutup — minta refresh data terbaru
    ref.invalidate(tailorByIdProvider(widget.initialTailor.id));
    ref.invalidate(tailorEfficiencyStatsProvider(widget.initialTailor.id));
    ref.invalidate(tailorsListProvider); // list juga ikut segar
  }

  @override
  Widget build(BuildContext context) {
    // Pantau data tailor terbaru dari DB; gunakan initialTailor sebagai
    // nilai awal/fallback selama loading.
    final tailorAsync = ref.watch(tailorByIdProvider(widget.initialTailor.id));
    final tailor = tailorAsync.asData?.value ?? widget.initialTailor;

    final efficiencyAsync = ref.watch(
      tailorEfficiencyStatsProvider(widget.initialTailor.id),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          tailor.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.grey[200],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Ubah Data',
            onPressed: () => _openEditDialog(tailor),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Kartu Profil ──
              _buildProfileCard(context, tailor),
              const SizedBox(height: 20),

              // ── Sisa Perca & Efisiensi ──
              efficiencyAsync.when(
                data: (stats) => _buildEfficiencySection(context, stats),
                loading:
                    () => const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                error:
                    (err, _) => _buildErrorCard(
                      context,
                      'Gagal memuat data ringkasan: $err',
                      onRetry:
                          () => ref.invalidate(
                            tailorEfficiencyStatsProvider(
                              widget.initialTailor.id,
                            ),
                          ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Profil ─────────────────────────────────────────────────────────────────

  Widget _buildProfileCard(BuildContext context, TailorModel tailor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[400]!, Colors.green[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white,
            backgroundImage:
                tailor.tailorImages != null && tailor.tailorImages!.isNotEmpty
                    ? NetworkImage(tailor.tailorImages!)
                    : null,
            child:
                tailor.tailorImages == null || tailor.tailorImages!.isEmpty
                    ? Text(
                      tailor.name.isNotEmpty
                          ? tailor.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    )
                    : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tailor.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.phone, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      tailor.noTelp,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        tailor.address,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Efisiensi & Prediksi ──────────────────────────────────────────────────

  Widget _buildEfficiencySection(
    BuildContext context,
    Map<String, double> stats,
  ) {
    final sisaPerca = stats['sisa_perca'] ?? 0.0;
    final reff = stats['reff'] ?? 0.0;
    final prediksi = stats['prediksi_majun'] ?? 0.0;
    final totalPercaDiambil = stats['total_perca_diambil'] ?? 0.0;
    final totalMajunDisetor = stats['total_majun_disetor'] ?? 0.0;
    final totalLimbahDisetor = stats['total_limbah_disetor'] ?? 0.0;
    final reffPercent = (reff * 50).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Sisa Perca (utama) ──
        _buildSisaPercaCard(sisaPerca),
        const SizedBox(height: 16),

        // ── Statistik Historis ──
        const Text(
          'Riwayat Kerja',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: 'Perca\nDiambil',
                value: '${_fmt(totalPercaDiambil)} Kg',
                icon: Icons.inventory_2_outlined,
                color: Colors.blue[400]!,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                label: 'Majun\nDisetor',
                value: '${_fmt(totalMajunDisetor)} Kg',
                icon: Icons.check_circle_outline,
                color: Colors.green[400]!,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                label: 'Limbah\nDisetor',
                value: '${_fmt(totalLimbahDisetor)} Kg',
                icon: Icons.delete_outline,
                color: Colors.orange[400]!,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Reff & Prediksi ──
        const Text(
          'Kinerja & Perkiraan Hasil',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _buildReffCard(
          reffPercent: reffPercent,
          reff: reff,
          hasData: totalPercaDiambil > 0,
        ),
        const SizedBox(height: 12),
        _buildPrediksiCard(
          sisaPerca: sisaPerca,
          reff: reff,
          prediksi: prediksi,
          hasData: totalPercaDiambil > 0,
        ),
      ],
    );
  }

  // ── Widget: Sisa Perca (headline) ─────────────────────────────────────────

  Widget _buildSisaPercaCard(double sisaPerca) {
    final isHighStock = sisaPerca >= 50;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isHighStock ? Colors.amber[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighStock ? Colors.amber[400]! : Colors.green[300]!,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isHighStock ? Icons.warning_amber_rounded : Icons.home_outlined,
                color: isHighStock ? Colors.amber[700] : Colors.green[700],
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Sisa Bahan di Rumah',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isHighStock ? Colors.amber[800] : Colors.green[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${_fmt(sisaPerca)} Kg',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: isHighStock ? Colors.amber[800] : Colors.green[700],
            ),
          ),
          if (isHighStock) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber[800], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sisa bahan sudah mencapai 50 Kg atau lebih. '
                      'Sebaiknya cek dulu sebelum memberi bahan baru.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.amber[900],
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Widget: Kartu Reff ────────────────────────────────────────────────────

  Widget _buildReffCard({
    required String reffPercent,
    required double reff,
    required bool hasData,
  }) {
    String statusText = '';
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.info;
    Color statusBg = Colors.grey[50]!;

    if (hasData) {
      // Menyesuaikan perhitungan/threshold:
      // Karena reff = majun / total_perca_diambil, nilai 0.4 - 0.55 adalah nilai rata-rata
      // yang sangat normal dan wajar untuk penjahit (karena adanya sisa perca dan limbah).
      if (reff >= 0.55) {
        statusText = 'Hasil Bagus';
        statusColor = Colors.green[700]!;
        statusIcon = Icons.check_circle;
        statusBg = Colors.green[50]!;
      } else if (reff >= 0.40) {
        statusText = 'Hasil Sedang';
        statusColor = Colors.amber[800]!;
        statusIcon = Icons.info;
        statusBg = Colors.amber[50]!;
      } else {
        statusText = 'Hasil Rendah';
        statusColor = Colors.red[700]!;
        statusIcon = Icons.warning;
        statusBg = Colors.red[50]!;
      }
    }

    final yieldPer50 = (reff * 50).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.thumb_up_outlined, color: Colors.purple[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Kualitas Kerja Penjahit',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasData)
            Text(
              'Belum ada riwayat pekerjaan.',
              style: TextStyle(fontSize: 14, color: Colors.purple[600]),
            )
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, color: statusColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Dari 50 Kg perca, Perkiraan menjadi sekitar $yieldPer50 Kg majun jadi.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.purple[900],
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Widget: Kartu Prediksi ────────────────────────────────────────────────

  Widget _buildPrediksiCard({
    required double sisaPerca,
    required double reff,
    required double prediksi,
    required bool hasData,
  }) {
    final roundedPrediksi = prediksi.round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_rounded, color: Colors.teal[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Perkiraan Hasil Kedepan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasData || sisaPerca == 0)
            Text(
              sisaPerca == 0
                  ? 'Penjahit sedang tidak memegang bahan (0 Kg).'
                  : 'Belum bisa membuat perkiraan.',
              style: TextStyle(fontSize: 14, color: Colors.teal[600]),
            )
          else ...[
            Text(
              'Sekitar $roundedPrediksi Kg Majun',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.teal[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sisa bahan saat ini kira-kira bisa menghasilkan sekitar $roundedPrediksi Kg majun.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.teal[900],
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Widget: Stat kecil ────────────────────────────────────────────────────

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }

  // ── Widget: Error ─────────────────────────────────────────────────────────

  Widget _buildErrorCard(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 36),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red[700], fontSize: 13),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  /// Format double ke string ringkas.
  ///
  /// - Gunakan [truncateToDouble] (bukan modulo) untuk deteksi bilangan bulat
  ///   agar aman dari ketidakstabilan floating-point.
  /// - Bulatkan ke 2 desimal, hapus trailing zero, lalu hapus trailing titik.
  static String _fmt(double value) {
    if (value == value.truncateToDouble()) {
      return value.toStringAsFixed(0);
    }
    // "1.50" → hapus trailing zero → "1.5"
    // "1.00" (jika muncul setelah pembulatan) → "1." → hapus titik akhir → "1"
    final str = value.toStringAsFixed(2);
    final trimmed = str
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
    return trimmed;
  }
}
