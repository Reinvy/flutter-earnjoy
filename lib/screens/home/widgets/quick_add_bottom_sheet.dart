import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../core/extensions.dart';
import '../../../core/theme.dart';
import '../../../providers/activity_provider.dart';

/// Modal bottom sheet exposing [presetActivities] for quick logging.
/// Pops with the earned [double] on success, or `null` on dismiss/block.
class QuickAddBottomSheet extends StatelessWidget {
  const QuickAddBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.md,
          AppSpacing.screenH,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textDisabled,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Log Activity', style: AppText.title),
            const SizedBox(height: AppSpacing.sm),
            ...presetActivities.map(
              (preset) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _PresetTile(preset: preset),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  final Map<String, dynamic> preset;

  const _PresetTile({required this.preset});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _log(context),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryDim,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                _iconForCategory(preset['category'] as String),
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Title + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(preset['title'] as String, style: AppText.title),
                  const SizedBox(height: 2),
                  Text(
                    '${preset['category']}  ·  ${(preset['durationMinutes'] as int).minutesToLabel}',
                    style: AppText.caption,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  void _log(BuildContext context) {
    HapticFeedback.mediumImpact();
    final earned = context.read<ActivityProvider>().logActivity(
      title: preset['title'] as String,
      category: preset['category'] as String,
      durationMinutes: preset['durationMinutes'] as int,
    );
    Navigator.pop(context, earned);
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Work':
        return Icons.work_outline;
      case 'Study':
        return Icons.menu_book_outlined;
      case 'Health':
        return Icons.fitness_center;
      case 'Hobby':
        return Icons.palette_outlined;
      case 'Fun':
        return Icons.sports_esports_outlined;
      default:
        return Icons.star_outline;
    }
  }
}
