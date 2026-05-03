import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/expedition_model.dart';
import '../../domain/expedition_provider.dart';

/// Screen riwayat expedisi (hanya tampilan, tanpa aksi tambah/hapus)
/// Digunakan oleh Manager untuk memantau semua pengiriman
class ExpeditionHistoryScreen extends ConsumerStatefulWidget {
  const ExpeditionHistoryScreen({
    super.key,
    this.openLatestOnLoad = false,
  });

  final bool openLatestOnLoad;

  @override
  ConsumerState<ExpeditionHistoryScreen> createState() =>
      _ExpeditionHistoryScreenState();
}

class _ExpeditionHistoryScreenState
    extends ConsumerState<ExpeditionHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _dateRange;
  String? _initialExpandedId;
  bool _initialExpansionResolved = false;

  int _currentPage = 0;
  static const int _pageSize = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final selectedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDateRange: _dateRange,
      helpText: 'Pilih rentang tanggal kirim',
    );

    if (selectedRange != null) {
      setState(() => _dateRange = selectedRange);
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _dateRange = null;
      _currentPage = 0;
    });
  }

  ExpeditionModel _findLatestExpedition(List<ExpeditionModel> expeditions) {
    ExpeditionModel latest = expeditions.first;

    for (final item in expeditions.skip(1)) {
      if (item.expeditionDate.isAfter(latest.expeditionDate)) {
        latest = item;
      }
    }

    return latest;
  }

  void _resolveInitialExpansion(List<ExpeditionModel> expeditions) {
    if (_initialExpansionResolved || !widget.openLatestOnLoad) return;
    _initialExpansionResolved = true;

    if (expeditions.isEmpty) return;
    _initialExpandedId = _findLatestExpedition(expeditions).id;
  }

  List<ExpeditionModel> _applyFilters(List<ExpeditionModel> expeditions) {
    final query = _searchController.text.trim().toLowerCase();

    return expeditions.where((expedition) {
      final destination = expedition.destination.toLowerCase();
      final partner = expedition.partnerName?.toLowerCase() ?? '';
      final matchesSearch =
          query.isEmpty || destination.contains(query) || partner.contains(query);

      final expeditionDate = DateTime(
        expedition.expeditionDate.year,
        expedition.expeditionDate.month,
        expedition.expeditionDate.day,
      );

      final matchesDate =
          _dateRange == null ||
          (!expeditionDate.isBefore(
                DateTime(
                  _dateRange!.start.year,
                  _dateRange!.start.month,
                  _dateRange!.start.day,
                ),
              ) &&
              !expeditionDate.isAfter(
                DateTime(
                  _dateRange!.end.year,
                  _dateRange!.end.month,
                  _dateRange!.end.day,
                ),
              ));

      return matchesSearch && matchesDate;
    }).toList();
  }

  Widget _buildFilterSection() {
    final hasFilter = _searchController.text.isNotEmpty || _dateRange != null;
    final dateLabel =
        _dateRange == null
            ? 'Semua tanggal'
            : '${DateFormat('dd MMM yyyy').format(_dateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_dateRange!.end)}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {
              _currentPage = 0;
            }),
            decoration: InputDecoration(
              hintText: 'Cari tujuan atau partner...',
              prefixIcon: const Icon(Icons.search, color: AppColors.greyDark),
              suffixIcon:
                  _searchController.text.isEmpty
                      ? null
                      : IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.greyDark),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.calendar_month_outlined, size: 18),
                  label: Text(
                    dateLabel,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (hasFilter) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Reset'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan provider yang sama dengan ManageExpeditionsScreen
    final expeditionsAsync = ref.watch(expeditionListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Pengiriman',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
        actions: [
          // Tombol refresh untuk memuat ulang daftar riwayat
          IconButton(
            onPressed: () => ref.invalidate(expeditionListProvider),
            icon: const Icon(Icons.refresh, color: AppColors.black),
            tooltip: 'Refresh',
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildFilterSection(),
            const SizedBox(height: 12),
            Expanded(
              child: expeditionsAsync.when(
                // Tampilkan daftar riwayat jika data berhasil dimuat
                data: (expeditions) {
                  _resolveInitialExpansion(expeditions);
                  final filteredExpeditions = _applyFilters(expeditions);

                  if (filteredExpeditions.isEmpty) {
                    final emptyMessage =
                        expeditions.isEmpty
                            ? 'Belum ada riwayat pengiriman.'
                            : 'Data tidak ditemukan untuk filter saat ini.';

                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.local_shipping_outlined,
                            size: 64,
                            color: AppColors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            emptyMessage,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.greyDark,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  final totalPages = (filteredExpeditions.length / _pageSize).ceil();
                  final safePage = _currentPage.clamp(0, totalPages - 1 >= 0 ? totalPages - 1 : 0);
                  final start = safePage * _pageSize;
                  final end = (start + _pageSize).clamp(0, filteredExpeditions.length);
                  final pageExpeditions = filteredExpeditions.sublist(start, end);

                  // Tampilkan ListView semua riwayat expedisi
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: pageExpeditions.length,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: _buildHistoryCard(
                                context,
                                pageExpeditions[index],
                                initiallyExpanded:
                                    pageExpeditions[index].id ==
                                    _initialExpandedId,
                              ),
                            );
                          },
                        ),
                      ),
                      if (totalPages > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: safePage > 0
                                    ? () => setState(() => _currentPage = safePage - 1)
                                    : null,
                              ),
                              Text(
                                'Halaman ${safePage + 1} dari $totalPages',
                                style: const TextStyle(fontSize: 14, color: AppColors.greyDark),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: safePage < totalPages - 1
                                    ? () => setState(() => _currentPage = safePage + 1)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
                // Tampilkan loading indicator saat data sedang dimuat
                loading:
                    () => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                // Tampilkan pesan error jika gagal memuat data
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Gagal memuat riwayat: $error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error),
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
            ),
          ],
        ),
      ),
    );
  }

  /// Kartu riwayat satu expedisi (read-only, tanpa tombol hapus)
  Widget _buildHistoryCard(
    BuildContext context,
    ExpeditionModel expedition, {
    bool initiallyExpanded = false,
  }) {
    // Format tanggal ke format yang mudah dibaca
    final dateFormatted =
        DateFormat('dd MMM yyyy').format(expedition.expeditionDate);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        key: PageStorageKey<String>('expedition-tile-${expedition.id}'),
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // Judul: nama tujuan pengiriman
        title: Row(
          children: [
            const Icon(
              Icons.local_shipping,
              color: AppColors.secondary,
              size: 20,
            ),
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
                style: const TextStyle(fontSize: 13, color: AppColors.greyDark),
              ),
              const SizedBox(height: 2),
              Text(
                '${expedition.sackNumber} Karung  •  ${expedition.totalWeight} KG',
                style: const TextStyle(fontSize: 13, color: AppColors.greyDark),
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
                        color: AppColors.secondary,
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
          Icon(icon, size: 16, color: AppColors.grey),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: AppColors.greyDark),
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
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.black,
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
                  child: CircularProgressIndicator(color: AppColors.primary),
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
