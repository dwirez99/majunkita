// lib/features/dashboard/presentation/widgets/user_profile_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../manage_partner/presentations/widgets/personal_info_edit_dialog.dart';

class UserProfileCard extends ConsumerWidget {
  const UserProfileCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return userProfileAsync.when(
      loading:
          () => _buildCard(
            context: context,
            name: 'Memuat...',
            role: '...',
            onEdit: null,
          ),
      error:
          (_, __) => _buildCard(
            context: context,
            name: 'Pengguna',
            role: 'Unknown',
            onEdit: () => _openEditDialog(context),
          ),
      data: (profile) {
        final rawName =
            (profile?['name'] ?? profile?['nama_lengkap'] ?? 'Pengguna')
                .toString();
        final rawRole = (profile?['role'] ?? 'staff').toString();

        return _buildCard(
          context: context,
          name: rawName,
          role: _capitalize(rawRole),
          onEdit: () => _openEditDialog(context),
        );
      },
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String name,
    required String role,
    VoidCallback? onEdit,
  }) {
    return Card(
      color: AppColors.cardBackground,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.cardBorder, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.person, color: AppColors.white),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.black,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          role,
          style: const TextStyle(color: AppColors.grey, fontSize: 12),
        ),
        trailing: IconButton(
          tooltip: 'Edit Informasi Pribadi',
          onPressed: onEdit,
          icon: const Icon(Icons.edit, color: AppColors.primary),
        ),
      ),
    );
  }

  void _openEditDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const PersonalInfoEditDialog(),
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}
