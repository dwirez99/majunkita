import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/wa_notification_item_model.dart';
import '../../domain/providers/wa_notifications_provider.dart';

class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState
    extends ConsumerState<AdminNotificationsScreen> {
  static const _filterOptions = [
    'all',
    'pending',
    'processing',
    'sent',
    'failed',
  ];

  String _statusLabel(String value) {
    switch (value) {
      case 'all':
        return 'Semua';
      case 'pending':
        return 'Menunggu';
      case 'processing':
        return 'Diproses';
      case 'sent':
        return 'Terkirim';
      case 'failed':
        return 'Gagal';
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedFilter = ref.watch(waNotificationsFilterProvider);
    final notificationsAsync = ref.watch(waNotificationsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi WhatsApp'),
        backgroundColor: AppColors.white,
      ),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Text(
                  'Filter status:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedFilter,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items:
                        _filterOptions
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(_statusLabel(value)),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      ref
                          .read(waNotificationsFilterProvider.notifier)
                          .setStatus(value);
                      ref.invalidate(waNotificationsListProvider);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Muat ulang',
                  onPressed: () => ref.invalidate(waNotificationsListProvider),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          Expanded(
            child: notificationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Gagal memuat notifikasi: $error'),
                    ),
                  ),
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text('Belum ada data notifikasi WhatsApp.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _NotificationCard(
                      item: item,
                      onRetry:
                          item.isFailed
                              ? () async {
                                try {
                                  await ref
                                      .read(
                                        waNotificationActionProvider.notifier,
                                      )
                                      .retry(item.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Coba kirim ulang dijadwalkan. Menunggu proses worker.',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Gagal coba ulang: $e'),
                                      ),
                                    );
                                  }
                                }
                              }
                              : null,
                      onManualSend:
                          item.isFailed
                              ? () => _openManualSendDialog(context, item)
                              : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openManualSendDialog(
    BuildContext context,
    WaNotificationItemModel item,
  ) async {
    final controller = TextEditingController(text: item.message);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Kirim Manual ke WhatsApp'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tujuan: ${item.recipientPhone}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Pesan',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: controller.text));
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Pesan disalin ke clipboard')),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final phone = _normalizeForWa(item.recipientPhone);
                final text = Uri.encodeComponent(controller.text.trim());
                final uri = Uri.parse('https://wa.me/$phone?text=$text');
                final ok = await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );

                if (!ok && dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Tidak bisa membuka WhatsApp. Pesan sudah bisa dicopy manual.',
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.send),
              label: const Text('Buka WhatsApp'),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  String _normalizeForWa(String jidOrPhone) {
    final noSuffix = jidOrPhone.replaceAll('@s.whatsapp.net', '');
    return noSuffix.replaceAll(RegExp(r'[^0-9]'), '');
  }
}

class _NotificationCard extends StatelessWidget {
  final WaNotificationItemModel item;
  final Future<void> Function()? onRetry;
  final VoidCallback? onManualSend;

  const _NotificationCard({
    required this.item,
    this.onRetry,
    this.onManualSend,
  });

  String _statusText(String status) {
    switch (status) {
      case 'sent':
        return 'TERKIRIM';
      case 'failed':
        return 'GAGAL';
      case 'processing':
        return 'DIPROSES';
      case 'pending':
        return 'MENUNGGU';
      default:
        return status.toUpperCase();
    }
  }

  String _roleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'penjahit':
        return 'Penjahit';
      case 'manager':
        return 'Manajer';
      case 'admin':
        return 'Admin';
      default:
        return role;
    }
  }

  String _eventLabel(String eventType) {
    switch (eventType) {
      case 'setor_majun':
        return 'Setor majun';
      case 'penarikan_upah':
        return 'Penarikan upah';
      case 'tambah_stok_perca':
        return 'Tambah stok perca';
      case 'expedition':
        return 'Pengiriman';
      default:
        return eventType.replaceAll('_', ' ');
    }
  }

  String _tableLabel(String sourceTable) {
    switch (sourceTable) {
      case 'majun_transactions':
        return 'Transaksi majun';
      case 'salary_withdrawals':
        return 'Penarikan upah';
      case 'percas_stock':
        return 'Stok perca';
      case 'expeditions':
        return 'Ekspedisi';
      default:
        return sourceTable.replaceAll('_', ' ');
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'sent':
        return AppColors.success;
      case 'failed':
        return AppColors.error;
      case 'processing':
        return AppColors.info;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(item.status);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${item.eventType} • ${item.sourceTable}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusText(item.status),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Dari: ${_eventLabel(item.eventType)} (${_tableLabel(item.sourceTable)})',
          ),
          const SizedBox(height: 4),
          Text(
            'Kirim ke: ${item.recipientPhone} (${_roleLabel(item.recipientRole)})',
          ),
          const SizedBox(height: 8),
          const Text('Pesan:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(item.message),
          if ((item.imageUrl ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Gambar:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.imageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Gambar tidak dapat dimuat',
                        style: TextStyle(color: AppColors.greyDark),
                      ),
                    ),
              ),
            ),
          ],
          if (onRetry != null || onManualSend != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                if (onRetry != null)
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba ulang'),
                  ),
                if (onManualSend != null)
                  ElevatedButton.icon(
                    onPressed: onManualSend,
                    icon: const Icon(Icons.send),
                    label: const Text('Kirim manual'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
