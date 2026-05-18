import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whatsapp_share_plus/whatsapp_share_plus.dart';
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
  static const _statusOptions = [
    'all',
    'pending',
    'processing',
    'sent',
    'failed',
  ];

  static const _eventOptions = [
    'all',
    'setor_majun',
    'penarikan_upah',
    'tambah_stok_perca',
    'pengambilan_perca',
    'expedition',
  ];

  String _statusLabel(String value) {
    switch (value) {
      case 'all':
        return 'Semua Status';
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

  String _eventLabel(String value) {
    if (value == 'all') return 'Semua Tipe';
    switch (value) {
      case 'setor_majun':
        return 'Setor majun';
      case 'penarikan_upah':
        return 'Penarikan upah';
      case 'tambah_stok_perca':
        return 'Tambah stok perca';
      case 'pengambilan_perca':
        return 'Pengambilan perca';
      case 'expedition':
        return 'Pengiriman';
      default:
        return value.replaceAll('_', ' ');
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
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedFilter.status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: _statusOptions
                        .map((value) => DropdownMenuItem(
                              value: value,
                              child: Text(
                                _statusLabel(value),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      ref.read(waNotificationsFilterProvider.notifier).setStatus(value);
                      ref.invalidate(waNotificationsListProvider);
                    },
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedFilter.eventType ?? 'all',
                    decoration: const InputDecoration(
                      labelText: 'Tipe Notifikasi',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: _eventOptions
                        .map((value) => DropdownMenuItem(
                              value: value,
                              child: Text(
                                _eventLabel(value),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      ref.read(waNotificationsFilterProvider.notifier).setEventType(value == 'all' ? null : value);
                      ref.invalidate(waNotificationsListProvider);
                    },
                  ),
                ),
                SizedBox(
                  width: 230,
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                        initialDateRange: selectedFilter.startDate != null && selectedFilter.endDate != null
                            ? DateTimeRange(start: selectedFilter.startDate!, end: selectedFilter.endDate!)
                            : null,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: AppColors.primary,
                                onPrimary: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        ref.read(waNotificationsFilterProvider.notifier).setDateRange(picked.start, picked.end);
                        ref.invalidate(waNotificationsListProvider);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Tanggal',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        suffixIcon: selectedFilter.startDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  ref.read(waNotificationsFilterProvider.notifier).setDateRange(null, null);
                                  ref.invalidate(waNotificationsListProvider);
                                },
                              )
                            : const Icon(Icons.calendar_today, size: 20),
                      ),
                      child: Text(
                        selectedFilter.startDate != null && selectedFilter.endDate != null
                            ? '${selectedFilter.startDate!.day.toString().padLeft(2, '0')}/${selectedFilter.startDate!.month.toString().padLeft(2, '0')}/${selectedFilter.startDate!.year} - ${selectedFilter.endDate!.day.toString().padLeft(2, '0')}/${selectedFilter.endDate!.month.toString().padLeft(2, '0')}/${selectedFilter.endDate!.year}'
                            : 'Semua Waktu',
                        style: const TextStyle(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    String initialText = item.message;
    if ((item.imageUrl ?? '').isNotEmpty) {
      try {
        final url = Uri.parse('https://tinyurl.com/api-create.php?url=${Uri.encodeComponent(item.imageUrl!)}');
        final request = await HttpClient().getUrl(url);
        final response = await request.close();
        final bytes = await consolidateHttpClientResponseBytes(response);
        final shortUrl = String.fromCharCodes(bytes);
        initialText += '\n\nLampiran Gambar:\n$shortUrl';
      } catch (_) {
        initialText += '\n\nLampiran Gambar:\n${item.imageUrl}';
      }
    }

    if (context.mounted) {
      Navigator.pop(context); // close loading dialog
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _ManualSendDialog(
          item: item,
          initialText: initialText,
          onNormalizeForWa: _normalizeForWa,
        );
      },
    );
  }

  String _normalizeForWa(String jidOrPhone) {
    final noSuffix = jidOrPhone.replaceAll('@s.whatsapp.net', '');
    var digits = noSuffix.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0')) {
      digits = '62${digits.substring(1)}';
    }
    return digits;
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

class _ManualSendDialog extends StatefulWidget {
  final WaNotificationItemModel item;
  final String initialText;
  final String Function(String) onNormalizeForWa;

  const _ManualSendDialog({
    Key? key,
    required this.item,
    required this.initialText,
    required this.onNormalizeForWa,
  }) : super(key: key);

  @override
  State<_ManualSendDialog> createState() => _ManualSendDialogState();
}

class _ManualSendDialogState extends State<_ManualSendDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kirim Manual ke WhatsApp'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tujuan: ${widget.item.recipientPhone}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _controller,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Pesan',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 255, 62, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Batal',
            style: TextStyle(color: Colors.white),
          ),
        ),
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: _controller.text));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pesan disalin ke clipboard')),
              );
            }
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copy'),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            final phone = widget.onNormalizeForWa(widget.item.recipientPhone);
            final textEncoded = Uri.encodeComponent(_controller.text.trim());
            final uri = Uri.parse('https://wa.me/$phone?text=$textEncoded');
            final ok = await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );

            if (!ok && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
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
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
          ),
        ),
      ],
    );
  }
}
