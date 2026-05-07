// lib/features/dashboard/presentation/widgets/user_profile_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../manage_partner/presentations/widgets/personal_info_edit_dialog.dart';

class UserProfileCard extends ConsumerWidget {
  /// Gradient applied to the card background.
  /// Defaults to the primary → secondaryLight gradient used across dashboards.
  final LinearGradient? gradient;

  /// Icon shown on the trailing end of the card (e.g. a role-specific icon).
  /// Defaults to [Icons.person].
  final IconData trailingIcon;

  const UserProfileCard({
    super.key,
    this.gradient,
    this.trailingIcon = Icons.person,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return userProfileAsync.when(
      loading:
          () => _buildCard(
            name: 'Memuat...',
            role: '...',
            onEdit: null,
          ),
      error:
          (_, __) => _buildCard(
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
          name: rawName,
          role: _capitalize(rawRole),
          onEdit: () => _openEditDialog(context),
        );
      },
    );
  }

  Widget _buildCard({
    required String name,
    required String role,
    VoidCallback? onEdit,
  }) {
    final effectiveGradient = gradient ??
        const LinearGradient(
          colors: [AppColors.primary, AppColors.secondaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: effectiveGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
          // Avatar circle
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: AppColors.white, size: 32),
          ),
          const SizedBox(width: 14),

          // Name + role badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    role,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Edit button
          if (onEdit != null)
            IconButton(
              tooltip: 'Edit Informasi Pribadi',
              onPressed: onEdit,
              icon: Icon(
                Icons.edit,
                color: AppColors.white.withValues(alpha: 0.85),
                size: 20,
              ),
            ),

          // Trailing role icon
          Icon(trailingIcon, color: AppColors.white, size: 32),
        ],
      ),
    ));
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
