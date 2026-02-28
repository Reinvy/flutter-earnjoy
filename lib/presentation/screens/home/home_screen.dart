import 'dart:async';
import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:earnjoy/core/constants.dart';
import 'package:earnjoy/core/extensions.dart';
import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/core/widgets/gradient_button.dart';
import 'package:earnjoy/data/models/badge.dart' as earnjoy_badge;
import 'package:earnjoy/data/models/game_event.dart';
import 'package:earnjoy/presentation/providers/activity_provider.dart';
import 'package:earnjoy/presentation/providers/badge_provider.dart';
import 'package:earnjoy/presentation/providers/event_provider.dart';
import 'package:earnjoy/presentation/providers/user_provider.dart';
import 'widgets/activity_card.dart';
import 'widgets/quick_add_bottom_sheet.dart';
import 'widgets/quest_carousel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<earnjoy_badge.Badge>? _badgeSub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _badgeSub?.cancel();
    _badgeSub = context.read<BadgeProvider>().onBadgeUnlocked.listen(_onBadgeUnlocked);
  }

  void _onBadgeUnlocked(earnjoy_badge.Badge badge) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
        ),
        content: Row(
          children: [
            const Text('🏅', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Badge Baru: ${badge.name}',
                    style: AppText.title.copyWith(color: AppColors.primary, fontSize: 14),
                  ),
                  Text(badge.description, style: AppText.caption),
                ],
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _badgeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final todayActivities = context.watch<ActivityProvider>().todayActivities;
    final todayEarned = todayActivities.fold<double>(0, (s, a) => s + a.points);
    final isBurnedOut = userProvider.isBurnedOut;

    // Sorted unlocked badges – most recently unlocked last
    final unlockedBadges = List.of(context.watch<BadgeProvider>().unlockedBadges)
      ..sort((a, b) => (a.unlockedAt ?? DateTime(2000)).compareTo(b.unlockedAt ?? DateTime(2000)));
    final latestBadge = unlockedBadges.lastOrNull;

    final activeEvents = context.watch<EventProvider>().activeEvents;

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

                    // ── Hero balance ────────────────────────────────────────
                    _HeroMetric(
                      balance: user.pointBalance,
                      latestBadge: latestBadge,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // ── Streak + daily progress ─────────────────────────────
                    Row(
                      children: [
                        _StreakBadge(streak: user.streak),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: _DailyProgressBar(todayEarned: todayEarned)),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.sectionGap),

                    // ── Active event banner(s) ──────────────────────────────
                    if (activeEvents.isNotEmpty) ...[
                      for (final event in activeEvents) ...[
                        _EventBanner(event: event),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ],

                    // ── Burnout flag ────────────────────────────────────────
                    if (isBurnedOut) ...[
                      _BurnoutBanner(
                        onDismiss: () => context.read<UserProvider>().dismissBurnout(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // ── Daily quests carousel ───────────────────────────────
                    const QuestCarousel(),
                    const SizedBox(height: AppSpacing.sectionGap),

                    // ── Today's activities ──────────────────────────────────
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

            // ── Floating CTA ──────────────────────────────────────────────
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

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _HeroMetric extends StatelessWidget {
  final double balance;
  final earnjoy_badge.Badge? latestBadge;
  const _HeroMetric({required this.balance, this.latestBadge});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radial glow
          Container(
            width: 240,
            height: 240,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.heroGlow,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(balance.toPointsLabel, style: AppText.displayLarge),
              const SizedBox(height: 4),
              const Text('total points', style: AppText.caption),
              if (latestBadge != null) ...[
                const SizedBox(height: 10),
                _MicroTrophy(badge: latestBadge!),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MicroTrophy extends StatelessWidget {
  final earnjoy_badge.Badge badge;
  const _MicroTrophy({required this.badge});

  IconData _iconFor(String name) => switch (name) {
    'local_fire_department' => Icons.local_fire_department_rounded,
    'emoji_events' => Icons.emoji_events_rounded,
    'military_tech' => Icons.military_tech_rounded,
    'redeem' => Icons.redeem_rounded,
    _ => Icons.star_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(badge.icon), size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            badge.name,
            style: AppText.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
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
        ),
      ],
    );
  }
}

class _EventBanner extends StatelessWidget {
  final GameEvent event;
  const _EventBanner({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryDim,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.flash_on_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚡ ${event.name}',
                  style: AppText.title.copyWith(color: AppColors.primary, fontSize: 14),
                ),
                Text(event.description, style: AppText.caption),
              ],
            ),
          ),
          if (event.multiplier > 1.0) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryDim,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                '×${event.multiplier.toStringAsFixed(1)}',
                style: AppText.caption.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
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
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
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
