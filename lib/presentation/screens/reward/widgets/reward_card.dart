import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:earnjoy/core/extensions.dart';
import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/data/models/reward.dart';

class RewardCard extends StatelessWidget {
  final Reward reward;

  /// The user's current point balance - used to compute progress and unlock state.
  final double userBalance;
  final VoidCallback? onRedeem;
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;

  const RewardCard({
    super.key,
    required this.reward,
    required this.userBalance,
    this.onRedeem,
    this.onDelete,
    this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final isRedeemed = reward.isRedeemed;
    final bool canRedeem = _canRedeem();
    final progress = reward.progressFractionForBalance(userBalance);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: canRedeem
              ? AppColors.primary.withValues(alpha: 0.6)
              : isRedeemed
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.glassBorder,
          width: canRedeem ? 1.5 : 1,
        ),
        gradient: canRedeem
            ? LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.surface.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  AppColors.surfaceHigh.withValues(alpha: 0.3),
                  AppColors.surface.withValues(alpha: 0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: canRedeem
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header row ───────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji icon container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _iconBgColor,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: canRedeem
                        ? AppColors.primary.withValues(alpha: 0.25)
                        : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Text(
                    reward.iconEmoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Name + badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reward.name,
                      style: AppText.title.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isRedeemed
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        decoration:
                            isRedeemed ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Category badge
                        _CategoryBadge(category: reward.category),
                        const SizedBox(width: 6),
                        // Recurrence badge
                        if (reward.recurrenceType != RecurrenceType.once)
                          _RecurrenceBadge(reward: reward),
                      ],
                    ),
                  ],
                ),
              ),

              // Delete/archive menu
              if (!isRedeemed)
                _OverflowMenu(onDelete: onDelete, onArchive: onArchive),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // ─── Scheduled countdown ───────────────────────────────────────
          if (reward.scheduledFor != null && !isRedeemed)
            _ScheduledBanner(daysLeft: reward.scheduledDaysLeft ?? 0),

          // ─── Cooldown info for recurring ──────────────────────────────
          if (reward.recurrenceType == RecurrenceType.recurring &&
              !reward.isRecurringReady &&
              !isRedeemed)
            _CooldownBanner(daysLeft: reward.recurringCooldownDaysLeft),

          const SizedBox(height: AppSpacing.sm),

          // ─── Progress ─────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${userBalance.clamp(0.0, reward.pointCost).toPointsLabel} / ${reward.pointCost.toPointsLabel} pts',
                style: AppText.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: AppText.caption.copyWith(
                  color: canRedeem ? AppColors.primary : AppColors.textDisabled,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          if (!isRedeemed) _ProgressBar(fraction: progress),

          // ─── Actions ──────────────────────────────────────────────────
          if (canRedeem) ...[
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: onRedeem,
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      FaIcon(FontAwesomeIcons.gift, color: Colors.white, size: 12),
                      SizedBox(width: 6),
                      Text(
                        'Redeem Reward',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          if (isRedeemed && reward.recurrenceType == RecurrenceType.once) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const FaIcon(FontAwesomeIcons.circleCheck,
                    size: 13, color: AppColors.success),
                const SizedBox(width: 4),
                Text('Redeemed',
                    style:
                        AppText.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.bold)),
              ],
            ),
          ],

          // Times redeemed counter for recurring/limited
          if (reward.timesRedeemed > 0 &&
              reward.recurrenceType != RecurrenceType.once) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const FaIcon(FontAwesomeIcons.clockRotateLeft, size: 10, color: AppColors.textDisabled),
                const SizedBox(width: 4),
                Text(
                  'Redeemed ${reward.timesRedeemed}x',
                  style: AppText.caption.copyWith(fontSize: 10),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  bool _canRedeem() {
    if (!reward.canRedeemWithBalance(userBalance)) return false;
    if (reward.recurrenceType == RecurrenceType.recurring) {
      return reward.isRecurringReady;
    }
    return true;
  }

  Color get _iconBgColor {
    if (reward.isRedeemed) return AppColors.success.withValues(alpha: 0.12);
    if (_canRedeem()) return AppColors.primary.withValues(alpha: 0.15);
    return AppColors.surfaceHigh.withValues(alpha: 0.6);
  }
}

// ─── Small Helper Widgets ────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: _color.withValues(alpha: 0.18), width: 0.5),
      ),
      child: Text(
        '${RewardCategory.emoji(category)} ${RewardCategory.label(category)}',
        style: AppText.caption.copyWith(color: _color, fontSize: 9, fontWeight: FontWeight.w600),
      ),
    );
  }

  Color get _color => AppColors.rewardColorForCategory(category);
}

class _RecurrenceBadge extends StatelessWidget {
  final Reward reward;
  const _RecurrenceBadge({required this.reward});

  @override
  Widget build(BuildContext context) {
    String label = '';
    if (reward.recurrenceType == RecurrenceType.recurring) {
      label = '🔄 Tiap ${reward.recurrenceIntervalDays ?? 7}h';
    } else if (reward.recurrenceType == RecurrenceType.limited) {
      label = '📅 ≤${reward.monthlyLimit ?? 1}x/bln';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.18), width: 0.5),
      ),
      child: Text(
        label,
        style: AppText.caption.copyWith(
          color: AppColors.warning,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ScheduledBanner extends StatelessWidget {
  final int daysLeft;
  const _ScheduledBanner({required this.daysLeft});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 5),
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: const Color(0xFF5EC4F0).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: const Color(0xFF5EC4F0).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FaIcon(FontAwesomeIcons.calendarDay, size: 10, color: Color(0xFF5EC4F0)),
          const SizedBox(width: 6),
          Text(
            daysLeft == 0
                ? '🎉 Hari redeem tiba!'
                : '⏰ $daysLeft hari lagi',
            style: AppText.caption.copyWith(
              color: const Color(0xFF5EC4F0),
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _CooldownBanner extends StatelessWidget {
  final int daysLeft;
  const _CooldownBanner({required this.daysLeft});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 5),
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FaIcon(FontAwesomeIcons.stopwatch, size: 10, color: AppColors.warning),
          const SizedBox(width: 6),
          Text(
            'Cooldown: $daysLeft hari lagi',
            style: AppText.caption.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverflowMenu extends StatelessWidget {
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;
  const _OverflowMenu({this.onDelete, this.onArchive});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      iconSize: 14,
      icon: const FaIcon(FontAwesomeIcons.ellipsisVertical, size: 14, color: AppColors.textDisabled),
      color: AppColors.surfaceHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      onSelected: (value) {
        if (value == 'archive') onArchive?.call();
        if (value == 'delete') onDelete?.call();
      },
      itemBuilder: (_) => [
        if (onArchive != null)
          PopupMenuItem(
            value: 'archive',
            child: Row(
              children: [
                const FaIcon(FontAwesomeIcons.box,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text('Arsipkan', style: AppText.body.copyWith(fontSize: 13)),
              ],
            ),
          ),
        if (onDelete != null)
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                const FaIcon(FontAwesomeIcons.trash, size: 14, color: AppColors.error),
                const SizedBox(width: 8),
                Text('Hapus', style: AppText.body.copyWith(color: AppColors.error, fontSize: 13)),
              ],
            ),
          ),
      ],
    );
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
              alignment: Alignment.centerLeft,
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
