import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/expedition_partner_model.dart';
import '../../domain/expedition_provider.dart';

/// Screen untuk mengelola data mitra/perusahaan expedisi (CRUD).
/// Dapat dibuka dari ManageExpeditionsScreen atau dari form AddExpedition.
class ManageExpeditionPartnersScreen extends ConsumerStatefulWidget {
  const ManageExpeditionPartnersScreen({super.key});

  @override
  ConsumerState<ManageExpeditionPartnersScreen> createState() =>
      _ManageExpeditionPartnersScreenState();
}

class _ManageExpeditionPartnersScreenState
    extends ConsumerState<ManageExpeditionPartnersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final partnersAsync = ref.watch(expeditionPartnerListProvider);
    final actionState = ref.watch(manageExpeditionPartnerNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Mitra Expedisi',
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(expeditionPartnerListProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // ── Tombol Tambah ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: actionState.isLoading
                      ? null
                      : () => _showFormDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Tambah Mitra Expedisi',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Search Bar ───────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Cari nama mitra expedisi...',
                        ),
                        onChanged: (value) => ref
                            .read(expeditionPartnerSearchQueryProvider.notifier)
                            .setQuery(value),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(expeditionPartnerSearchQueryProvider
                                  .notifier)
                              .clear();
                        },
                      )
                    else
                      const Icon(Icons.search, color: Colors.grey),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── List ─────────────────────────────────────────────────────
              Expanded(
                child: partnersAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Gagal memuat data: $e',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () =>
                              ref.invalidate(expeditionPartnerListProvider),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                  data: (partners) {
                    if (partners.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_shipping_outlined,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'Belum ada mitra expedisi.\nTambahkan mitra baru.'
                                  : 'Mitra "${_searchController.text}" tidak ditemukan.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: partners.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildPartnerCard(context, partners[index]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Card ──────────────────────────────────────────────────────────────────

  Widget _buildPartnerCard(
      BuildContext context, ExpeditionPartnerModel partner) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(Icons.local_shipping,
                color: AppColors.secondary, size: 28),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partner.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (partner.noTelp != null && partner.noTelp!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone,
                          size: 13, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        partner.noTelp!,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
                if (partner.address != null &&
                    partner.address!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: Colors.white70),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          partner.address!,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white70),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Edit
          IconButton(
            onPressed: () => _showFormDialog(context, partnerToEdit: partner),
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.1),
            ),
          ),

          const SizedBox(width: 6),

          // Delete
          IconButton(
            onPressed: () => _showDeleteDialog(context, partner),
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ── Form Dialog (Add / Edit) ──────────────────────────────────────────────

  void _showFormDialog(BuildContext context,
      {ExpeditionPartnerModel? partnerToEdit}) {
    final isEdit = partnerToEdit != null;
    final nameCtrl =
        TextEditingController(text: partnerToEdit?.name ?? '');
    final noTelpCtrl =
        TextEditingController(text: partnerToEdit?.noTelp ?? '');
    final addressCtrl =
        TextEditingController(text: partnerToEdit?.address ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    isEdit ? 'Edit Mitra Expedisi' : 'Tambah Mitra Expedisi',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Nama
                  TextFormField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nama Mitra *',
                      hintText: 'contoh: JNE, TIKI, SiCepat',
                      prefixIcon: const Icon(Icons.local_shipping_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nama tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // No Telp
                  TextFormField(
                    controller: noTelpCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'No. Telepon',
                      hintText: 'opsional',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Alamat
                  TextFormField(
                    controller: addressCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Alamat',
                      hintText: 'opsional',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('BATAL'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            Navigator.pop(ctx);
                            try {
                              if (isEdit) {
                                await ref
                                    .read(manageExpeditionPartnerNotifierProvider
                                        .notifier)
                                    .updatePartner(
                                      id: partnerToEdit.id,
                                      name: nameCtrl.text.trim(),
                                      noTelp: noTelpCtrl.text.trim(),
                                      address: addressCtrl.text.trim(),
                                    );
                              } else {
                                await ref
                                    .read(manageExpeditionPartnerNotifierProvider
                                        .notifier)
                                    .createPartner(
                                      name: nameCtrl.text.trim(),
                                      noTelp: noTelpCtrl.text.trim(),
                                      address: addressCtrl.text.trim(),
                                    );
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isEdit
                                        ? 'Mitra berhasil diperbarui'
                                        : 'Mitra berhasil ditambahkan'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal: $e'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(isEdit ? 'SIMPAN' : 'TAMBAH'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Delete Dialog ─────────────────────────────────────────────────────────

  void _showDeleteDialog(
      BuildContext context, ExpeditionPartnerModel partner) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Hapus Mitra Expedisi'),
        content: Text(
          'Yakin ingin menghapus "${partner.name}"?\n\n'
          'Data expedisi yang menggunakan mitra ini tidak akan terhapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('BATAL', style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(
                        manageExpeditionPartnerNotifierProvider.notifier)
                    .deletePartner(partner.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${partner.name} berhasil dihapus'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('HAPUS'),
          ),
        ],
      ),
    );
  }
}
