import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:earnjoy/core/constants.dart';
import 'package:earnjoy/core/extensions.dart';
import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/core/widgets/gradient_button.dart';
import 'package:earnjoy/presentation/providers/activity_provider.dart';
import 'package:earnjoy/presentation/providers/user_provider.dart';
import 'widgets/activity_card.dart';
import 'widgets/quick_add_bottom_sheet.dart';
import 'widgets/quest_carousel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final todayActivities = context.watch<ActivityProvider>().todayActivities;
    final todayEarned = todayActivities.fold<double>(0, (s, a) => s + a.points);
    final isBurnedOut = userProvider.isBurnedOut;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),

                    _HeroMetric(balance: user.pointBalance),

                    const SizedBox(height: AppSpacing.lg),

                    Row(
                      children: [
                        _StreakBadge(streak: user.streak),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: _DailyProgressBar(todayEarned: todayEarned)),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.sectionGap),

                    if (isBurnedOut) ...[
                      _BurnoutBanner(
                        onDismiss: () => context.read<UserProvider>().dismissBurnout(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    const QuestCarousel(),
                    const SizedBox(height: AppSpacing.sectionGap),

                    const Text("Today's Activities", style: AppText.title),
                    const SizedBox(height: AppSpacing.sm),

                    if (todayActivities.isEmpty)
                      const _EmptyActivitiesState()
                    else
                      ...todayActivities.map(
                        (a) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: ActivityCard(activity: a),
                        ),
                      ),

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.sm,
                AppSpacing.screenH,
                AppSpacing.md,
              ),
              child: GradientButton(
                label: 'Log Activity',
                icon: Icons.add,
                onTap: () => _openQuickAdd(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openQuickAdd(BuildContext context) async {
    final earned = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      isScrollControlled: true,
      builder: (_) => const QuickAddBottomSheet(),
    );

    if (earned != null && earned > 0 && context.mounted) {
      _showMotivationSnackbar(context, earned);
    }
  }

  void _showMotivationSnackbar(BuildContext context, double points) {
    final msg = motivationMessages[Random().nextInt(motivationMessages.length)].replaceAll(
      '{points}',
      points.toStringAsFixed(0),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppText.body.copyWith(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surfaceHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}


class _HeroMetric extends StatelessWidget {
  final double balance;
  const _HeroMetric({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radial glow backdrop
          Container(
            width: 240,
            height: 240,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.heroGlow,
            ),
          ),
          // Balance text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(balance.toPointsLabel, style: AppText.displayLarge),
              const SizedBox(height: 4),
              const Text('total points', style: AppText.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, color: AppColors.success, size: 18),
          const SizedBox(width: 4),
          Text('$streak', style: AppText.title.copyWith(color: AppColors.success)),
          const SizedBox(width: 4),
          const Text('day streak', style: AppText.caption),
        ],
      ),
    );
  }
}

class _DailyProgressBar extends StatelessWidget {
  final double todayEarned;
  const _DailyProgressBar({required this.todayEarned});

  @override
  Widget build(BuildContext context) {
    final fraction = (todayEarned / maxPointsPerDay).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Daily cap', style: AppText.caption),
            Text(
              '${todayEarned.toStringAsFixed(0)} / ${maxPointsPerDay.toStringAsFixed(0)}',
              style: AppText.caption,
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: SizedBox(
            height: 6,
            child: Stack(
              children: [
                // Track
                Container(color: AppColors.primaryDim),
                // Fill
                FractionallySizedBox(
                  widthFactor: fraction,
                  child: Container(
                    decoration: const BoxDecoration(gradient: AppGradients.progressFill),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyActivitiesState extends StatelessWidget {
  const _EmptyActivitiesState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, color: AppColors.textDisabled, size: 48),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'No activities yet today.\nTap Log Activity to start earning!',
              style: AppText.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _BurnoutBanner extends StatelessWidget {
  final VoidCallback onDismiss;
  const _BurnoutBanner({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Burnout terdeteksi', style: AppText.title.copyWith(color: AppColors.warning)),
                const SizedBox(height: 2),
                const Text(
                  'Kamu melewatkan beberapa hari. Mulai kembali dengan aktivitas ringan!',
                  style: AppText.body,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close, size: 16, color: AppColors.textDisabled),
          ),
        ],
      ),
    );
  }
}
