// lib/features/Dashboard/presentations/widgets/summary_card.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  /// Widget opsional di sebelah kanan judul (misal badge tren "+12%")
  final Widget? trailingAction;

  const SummaryCard({
    super.key,
    required this.title,
    required this.children,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.cardBackground,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.cardBorder, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ),
                if (trailingAction != null) trailingAction!,
              ],
            ),
            const Divider(height: 20, color: AppColors.greyLight),
            ...children,
          ],
        ),
      ),
    );
  }
}