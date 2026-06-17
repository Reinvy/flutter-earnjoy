import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
          width: isAdded ? 1.5 : 1,
        ),
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceHigh.withValues(alpha: 0.3),
            AppColors.surface.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji header with category colored border
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md + 4),
            decoration: BoxDecoration(
              gradient: isAdded
                  ? LinearGradient(
                      colors: [AppColors.success.withValues(alpha: 0.12), AppColors.success.withValues(alpha: 0.02)],
                    )
                  : LinearGradient(
                      colors: [AppColors.surfaceHigh.withValues(alpha: 0.8), AppColors.surface.withValues(alpha: 0.3)],
                    ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.md - 1),
              ),
              border: Border(
                bottom: BorderSide(
                  color: isAdded 
                      ? AppColors.success.withValues(alpha: 0.2) 
                      : AppColors.glassBorder,
                ),
              ),
            ),
            child: Center(
              child: Text(
                template.iconEmoji,
                style: const TextStyle(fontSize: 34),
              ),
            ),
          ),

          // Info section
          Expanded(
            child: Padding(
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
                      color: _categoryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: _categoryColor.withValues(alpha: 0.18), width: 0.5),
                    ),
                    child: Text(
                      RewardCategory.label(template.category),
                      style: AppText.caption.copyWith(
                        color: _categoryColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  // Name
                  Expanded(
                    child: Text(
                      template.name,
                      style: AppText.title.copyWith(fontSize: 13, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 2),

                  // Cost
                  Text(
                    '${template.pointCost.toPointsLabel} pts',
                    style: AppText.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),

                  // Recurrence info
                  if (template.recurrenceType != RecurrenceType.once) ...[
                    const SizedBox(height: 2),
                    Text(
                      _recurrenceLabel,
                      style: AppText.caption.copyWith(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
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
                        color: isAdded ? AppColors.surfaceHigh.withValues(alpha: 0.6) : null,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        boxShadow: isAdded
                            ? null
                            : [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Center(
                        child: isAdded
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.check,
                                    size: 11,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Added',
                                    style: AppText.caption.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                '+ Add',
                                style: AppText.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color get _categoryColor => AppColors.rewardColorForCategory(template.category);

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
