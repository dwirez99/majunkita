// lib/features/dashboard/presentation/widgets/user_profile_card.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class UserProfileCard extends StatelessWidget {
  const UserProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'Admin User',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.black,
            fontSize: 14,
          ),
        ),
        subtitle: const Text(
          'ADMIN',
          style: TextStyle(
            color: AppColors.grey,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.edit,
          color: AppColors.primary,
        ),
      ),
    );
  }
}