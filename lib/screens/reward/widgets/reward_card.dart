import 'package:flutter/material.dart';

import '../../../core/extensions.dart';
import '../../../core/theme.dart';
import '../../../models/reward.dart';

class RewardCard extends StatelessWidget {
  final Reward reward;
  final VoidCallback? onRedeem;
  final VoidCallback? onDelete;

  const RewardCard({super.key, required this.reward, this.onRedeem, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isRedeemed = reward.isRedeemed;
    final isUnlocked = reward.isUnlocked;
    final progress = reward.progressFraction;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: isUnlocked ? AppGradients.glassOverlay : null,
        color: isUnlocked ? null : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isUnlocked ? AppColors.primary.withValues(alpha: 0.5) : AppColors.glassBorder,
          width: isUnlocked ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────────
          Row(
            children: [
              // Status icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _iconBgColor,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(_iconData, size: 18, color: _iconColor),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Name
              Expanded(
                child: Text(
                  reward.name,
                  style: AppText.title.copyWith(
                    color: isRedeemed ? AppColors.textSecondary : AppColors.textPrimary,
                    decoration: isRedeemed ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Delete button
              if (onDelete != null)
                GestureDetector(
                  onTap: onDelete,
                  child: const Padding(
                    padding: EdgeInsets.only(left: AppSpacing.sm),
                    child: Icon(Icons.close, size: 16, color: AppColors.textDisabled),
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Point cost ──────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${reward.progressPoints.toPointsLabel} / ${reward.pointCost.toPointsLabel} pts',
                style: AppText.caption,
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: AppText.caption.copyWith(
                  color: isUnlocked ? AppColors.primary : AppColors.textDisabled,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xs),

          // ── Progress bar ────────────────────────────────────────────────
          if (!isRedeemed) _ProgressBar(fraction: progress),

          // ── Redeem button ───────────────────────────────────────────────
          if (isUnlocked) ...[
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: onRedeem,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: const Center(child: Text('Redeem', style: AppText.title)),
              ),
            ),
          ],

          if (isRedeemed) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 14, color: AppColors.success),
                const SizedBox(width: 4),
                Text('Redeemed', style: AppText.caption.copyWith(color: AppColors.success)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color get _iconBgColor {
    if (reward.isRedeemed) return AppColors.success.withValues(alpha: 0.15);
    if (reward.isUnlocked) return AppColors.primary.withValues(alpha: 0.15);
    return AppColors.surfaceHigh;
  }

  Color get _iconColor {
    if (reward.isRedeemed) return AppColors.success;
    if (reward.isUnlocked) return AppColors.primary;
    return AppColors.textDisabled;
  }

  IconData get _iconData {
    if (reward.isRedeemed) return Icons.check_circle;
    if (reward.isUnlocked) return Icons.lock_open;
    return Icons.lock;
  }
}

class _ProgressBar extends StatelessWidget {
  final double fraction;
  const _ProgressBar({required this.fraction});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: SizedBox(
        height: 6,
        child: Stack(
          children: [
            Container(color: AppColors.primaryDim),
            FractionallySizedBox(
              widthFactor: fraction,
              child: Container(
                decoration: const BoxDecoration(gradient: AppGradients.progressFill),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
