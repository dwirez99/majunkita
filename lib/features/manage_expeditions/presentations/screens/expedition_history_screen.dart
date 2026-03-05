import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/expedition_model.dart';
import '../../domain/expedition_provider.dart';

/// Screen riwayat expedisi (hanya tampilan, tanpa aksi tambah/hapus)
/// Digunakan oleh Manager untuk memantau semua pengiriman
class ExpeditionHistoryScreen extends ConsumerWidget {
  const ExpeditionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Gunakan provider yang sama dengan ManageExpeditionsScreen
    final expeditionsAsync = ref.watch(expeditionListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Pengiriman',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.grey[200],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // Tombol refresh untuk memuat ulang daftar riwayat
          IconButton(
            onPressed: () => ref.invalidate(expeditionListProvider),
            icon: const Icon(Icons.refresh, color: Colors.black),
            tooltip: 'Refresh',
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: expeditionsAsync.when(
        // Tampilkan daftar riwayat jika data berhasil dimuat
        data: (expeditions) {
          if (expeditions.isEmpty) {
            // Tampilkan pesan kosong jika belum ada riwayat
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada riwayat pengiriman.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Tampilkan ListView semua riwayat expedisi
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: expeditions.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildHistoryCard(context, expeditions[index]),
              );
            },
          );
        },
        // Tampilkan loading indicator saat data sedang dimuat
        loading: () => const Center(child: CircularProgressIndicator()),
        // Tampilkan pesan error jika gagal memuat data
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Gagal memuat riwayat: $error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(expeditionListProvider),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Kartu riwayat satu expedisi (read-only, tanpa tombol hapus)
  Widget _buildHistoryCard(BuildContext context, ExpeditionModel expedition) {
    // Format tanggal ke format yang mudah dibaca
    final dateFormatted =
        DateFormat('dd MMM yyyy').format(expedition.expeditionDate);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // Judul: nama tujuan pengiriman
        title: Row(
          children: [
            const Icon(Icons.local_shipping, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                expedition.destination,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        // Subjudul: tanggal dan ringkasan berat
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateFormatted,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 2),
              Text(
                '${expedition.sackNumber} Karung  •  ${expedition.totalWeight} KG',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ),
        // Detail yang ditampilkan saat tile dibuka
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 4),

                // Nama partner (jika tersedia dari JOIN dengan profiles)
                if (expedition.partnerName != null)
                  _buildDetailRow(
                    icon: Icons.person_outline,
                    label: 'Partner',
                    value: expedition.partnerName!,
                  ),

                // Tanggal pengiriman
                _buildDetailRow(
                  icon: Icons.calendar_today,
                  label: 'Tanggal Kirim',
                  value: dateFormatted,
                ),

                // Jumlah karung
                _buildDetailRow(
                  icon: Icons.inventory_2_outlined,
                  label: 'Jumlah Karung',
                  value: '${expedition.sackNumber} Karung',
                ),

                // Total berat
                _buildDetailRow(
                  icon: Icons.scale,
                  label: 'Total Berat',
                  value: '${expedition.totalWeight} KG',
                ),

                // Bukti pengiriman (gambar)
                if (expedition.proofOfDelivery.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () =>
                        _showProofImage(context, expedition.proofOfDelivery),
                    child: const Text(
                      'Lihat Bukti Pengiriman',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Baris detail dengan ikon, label, dan nilai
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  /// Tampilkan gambar bukti pengiriman dalam dialog
  void _showProofImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Bukti Pengiriman'),
              automaticallyImplyLeading: false,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 1,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Image.network(
              url,
              semanticLabel: 'Bukti foto pengiriman',
              loadingBuilder: (ctx, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                );
              },
              errorBuilder: (_, __, ___) => const Padding(
                padding: EdgeInsets.all(32),
                child: Text('Gagal memuat gambar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
