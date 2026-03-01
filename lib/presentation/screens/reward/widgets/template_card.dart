import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:earnjoy/core/extensions.dart';
import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/data/models/reward.dart';

class TemplateCard extends StatelessWidget {
  final Reward template;
  final bool isAdded;
  final VoidCallback onAdd;

  const TemplateCard({
    super.key,
    required this.template,
    required this.isAdded,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isAdded
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.glassBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: isAdded
                  ? AppColors.success.withValues(alpha: 0.08)
                  : AppColors.surfaceHigh,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.md),
              ),
            ),
            child: Center(
              child: Text(
                template.iconEmoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _categoryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    RewardCategory.label(template.category),
                    style: AppText.caption.copyWith(
                      color: _categoryColor,
                      fontSize: 10,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                // Name
                Text(
                  template.name,
                  style: AppText.title.copyWith(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 2),

                // Cost
                Text(
                  '${template.pointCost.toPointsLabel} pts',
                  style: AppText.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                // Recurrence info
                if (template.recurrenceType != RecurrenceType.once) ...[
                  const SizedBox(height: 2),
                  Text(
                    _recurrenceLabel,
                    style: AppText.caption.copyWith(fontSize: 10),
                  ),
                ],

                const SizedBox(height: AppSpacing.sm),

                // Add button
                GestureDetector(
                  onTap: isAdded
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          onAdd();
                        },
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: isAdded ? null : AppGradients.primary,
                      color: isAdded ? AppColors.surfaceHigh : null,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Center(
                      child: isAdded
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check,
                                  size: 12,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Added',
                                  style: AppText.caption.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              '+ Add',
                              style: AppText.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color get _categoryColor => switch (template.category) {
        RewardCategory.food => const Color(0xFFFF9F43),
        RewardCategory.entertainment => AppColors.primary,
        RewardCategory.shopping => const Color(0xFFFF6B9D),
        RewardCategory.experience => const Color(0xFF5EC4F0),
        RewardCategory.selfGrowth => AppColors.success,
        RewardCategory.rest => const Color(0xFFB8B0FF),
        _ => AppColors.textSecondary,
      };

  String get _recurrenceLabel {
    return switch (template.recurrenceType) {
      RecurrenceType.recurring =>
        '🔄 Tiap ${template.recurrenceIntervalDays ?? 7} hari',
      RecurrenceType.limited =>
        '📅 Maks ${template.monthlyLimit ?? 1}x/bulan',
      _ => '',
    };
  }
}
