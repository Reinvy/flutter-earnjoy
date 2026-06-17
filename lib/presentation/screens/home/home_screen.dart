import 'dart:async';
import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import 'package:earnjoy/core/constants.dart';
import 'package:earnjoy/core/extensions.dart';
import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/data/models/badge.dart' as earnjoy_badge;
import 'package:earnjoy/data/models/game_event.dart';
import 'package:earnjoy/presentation/providers/activity_provider.dart';
import 'package:earnjoy/presentation/providers/badge_provider.dart';
import 'package:earnjoy/presentation/providers/event_provider.dart';
import 'package:earnjoy/presentation/providers/user_provider.dart';
import 'package:earnjoy/presentation/providers/wellbeing_provider.dart';
import 'package:earnjoy/domain/usecases/burnout_service.dart';
import 'widgets/activity_card.dart';
import 'widgets/quick_add_bottom_sheet.dart';
import 'widgets/quest_carousel.dart';
import 'widgets/quick_log_sheet.dart';

// ── Motivational quotes ──────────────────────────────────────────────────────
const _motivationalQuotes = [
  (quote: 'Konsistensi mengalahkan motivasi yang datang dan pergi.', author: 'Earnjoy'),
  (quote: 'Setiap langkah kecil hari ini adalah fondasi versi terbaik dirimu.', author: 'Earnjoy'),
  (quote: 'Disiplin adalah jembatan antara tujuan dan pencapaian.', author: 'Jim Rohn'),
  (quote: 'Kamu tidak harus sempurna — cukup lakukan satu hal baik hari ini.', author: 'Earnjoy'),
  (quote: 'Kebiasaan baik yang kecil lebih kuat dari niat besar yang jarang dilakukan.', author: 'Earnjoy'),
  (quote: 'Progress, bukan perfeksi.', author: 'Earnjoy'),
  (quote: 'Tubuh dan pikiran yang sehat adalah investasi terbaik.', author: 'Earnjoy'),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  StreamSubscription<earnjoy_badge.Badge>? _badgeSub;
  bool _fabOpen = false;

  // ── Animation controller for staggered section entrance ──────────────────
  late AnimationController _staggerCtrl;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  static const _sectionCount = 7;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnims = List.generate(_sectionCount, (i) {
      final start = (i * 0.12).clamp(0.0, 0.85);
      final end = (start + 0.35).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnims = List.generate(_sectionCount, (i) {
      final start = (i * 0.12).clamp(0.0, 0.85);
      final end = (start + 0.35).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.12),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _staggerCtrl.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _badgeSub?.cancel();
    _badgeSub = context
        .read<BadgeProvider>()
        .onBadgeUnlocked
        .listen(_onBadgeUnlocked);
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
            const FaIcon(FontAwesomeIcons.medal,
                size: 20, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Badge Baru: ${badge.name}',
                    style: AppText.title
                        .copyWith(color: AppColors.primary, fontSize: 14),
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
    _staggerCtrl.dispose();
    super.dispose();
  }

  // ── Greeting ────────────────────────────────────────────────────────────
  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat pagi';
    if (hour < 17) return 'Selamat siang';
    if (hour < 20) return 'Selamat sore';
    return 'Selamat malam';
  }

  // ── Quote of the day ────────────────────────────────────────────────────
  ({String quote, String author}) _quoteOfDay() {
    final dayIndex = DateTime.now().difference(DateTime(2024)).inDays;
    return _motivationalQuotes[dayIndex % _motivationalQuotes.length];
  }

  Widget _animated(int index, Widget child) {
    return FadeTransition(
      opacity: _fadeAnims[index],
      child: SlideTransition(
        position: _slideAnims[index],
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final todayActivities = context.watch<ActivityProvider>().todayActivities;
    final todayEarned =
        todayActivities.fold<double>(0, (s, a) => s + a.points);
    final isBurnedOut = userProvider.isBurnedOut;
    final wellbeing = context.watch<WellbeingProvider>();
    final burnoutStatus = wellbeing.status;

    final unlockedBadges =
        List.of(context.watch<BadgeProvider>().unlockedBadges)
          ..sort((a, b) => (a.unlockedAt ?? DateTime(2000))
              .compareTo(b.unlockedAt ?? DateTime(2000)));

    final recentBadges = unlockedBadges.reversed.take(5).toList();
    final activeEvents = context.watch<EventProvider>().activeEvents;
    final quote = _quoteOfDay();

    return GestureDetector(
      onTap: () {
        if (_fabOpen) setState(() => _fabOpen = false);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // ── Main scrollable content ─────────────────────────────────
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.md),

                    // [0] Greeting header
                    _animated(
                      0,
                      _GreetingHeader(
                        greeting: _greeting(),
                        name: user.name,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // [1] Hero glassmorphism card
                    _animated(
                      1,
                      _HeroCard(
                        balance: user.pointBalance,
                        level: userProvider.currentLevel,
                        tierName: userProvider.currentTierName,
                        xpProgress: userProvider.xpProgress,
                        xp: user.xp,
                        xpForNext: userProvider.xpForNextLevel,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // [2] Stats row (Streak, Poin Hari Ini, Level)
                    _animated(
                      2,
                      _StatsRow(
                        streak: user.streak,
                        todayEarned: todayEarned,
                        level: userProvider.currentLevel,
                      ),
                    ),

                    // Recent badges
                    if (recentBadges.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      _animated(
                        2,
                        _RecentBadgesRow(badges: recentBadges),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.sectionGap),

                    // Active event banners
                    if (activeEvents.isNotEmpty) ...[
                      for (final event in activeEvents) ...[
                        _EventBanner(event: event),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ],

                    // Burnout banners
                    if (burnoutStatus == BurnoutStatus.attention) ...[
                      _AttentionBanner(),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (burnoutStatus == BurnoutStatus.fatigue) ...[
                      _FatigueBanner(),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (burnoutStatus == BurnoutStatus.burnout) ...[
                      _BurnoutInterventionBanner(),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (isBurnedOut &&
                        burnoutStatus == BurnoutStatus.healthy) ...[
                      _BurnoutBanner(
                        onDismiss: () =>
                            context.read<UserProvider>().dismissBurnout(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // [3] Daily Quests
                    _animated(3, const QuestCarousel()),

                    const SizedBox(height: AppSpacing.sectionGap),

                    // [4] Motivational quote
                    _animated(
                      4,
                      _MotivationalQuote(
                          quote: quote.quote, author: quote.author),
                    ),

                    const SizedBox(height: AppSpacing.sectionGap),

                    // [5] Today's Activities
                    _animated(
                      5,
                      Row(
                        children: [
                          const Text("Today's Activities",
                              style: AppText.title),
                          const SizedBox(width: AppSpacing.sm),
                          if (todayActivities.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primaryDim,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                '${todayActivities.length}',
                                style: AppText.caption.copyWith(
                                  color: AppColors.primaryLight,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // [6] Activity list / empty state
                    _animated(
                      6,
                      todayActivities.isEmpty
                          ? const _EmptyActivitiesState()
                          : Column(
                              children: todayActivities
                                  .map(
                                    (a) => Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: AppSpacing.sm),
                                      child: ActivityCard(activity: a),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),

                    // Extra bottom padding for FAB clearance
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // ── FAB overlay (close on tap outside) ────────────────────────
            if (_fabOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _fabOpen = false),
                  child: Container(color: Colors.black.withValues(alpha: 0.35)),
                ),
              ),

            // ── FAB Speed Dial ────────────────────────────────────────────
            Positioned(
              right: AppSpacing.screenH,
              bottom: AppSpacing.xl,
              child: _FabSpeedDial(
                isOpen: _fabOpen,
                onToggle: () => setState(() => _fabOpen = !_fabOpen),
                onQuickLog: () {
                  setState(() => _fabOpen = false);
                  _openQuickLog(context);
                },
                onLogActivity: () {
                  setState(() => _fabOpen = false);
                  _openQuickAdd(context);
                },
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
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      isScrollControlled: true,
      builder: (_) => const QuickAddBottomSheet(),
    );

    if (earned != null && earned > 0 && context.mounted) {
      _showMotivationSnackbar(context, earned);
    }
  }

  void _openQuickLog(BuildContext context, {String? presetTitle}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => QuickLogSheet(presetTitle: presetTitle),
    );
  }

  void _showMotivationSnackbar(BuildContext context, double points) {
    final msg = motivationMessages[Random().nextInt(motivationMessages.length)]
        .replaceAll('{points}', points.toStringAsFixed(0));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: AppText.body.copyWith(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surfaceHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ══════════════════════════════════════════════════════════════════════════════

// ── Greeting header ──────────────────────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  final String greeting;
  final String name;
  const _GreetingHeader({required this.greeting, required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, ${name.isEmpty ? 'Kamu' : name} 👋',
                style: AppText.title.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 2),
              const Text(
                'Yuk, lanjutkan streak kamu hari ini!',
                style: AppText.body,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Hero glassmorphism card ──────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final double balance;
  final int level;
  final String tierName;
  final double xpProgress;
  final double xp;
  final double xpForNext;

  const _HeroCard({
    required this.balance,
    required this.level,
    required this.tierName,
    required this.xpProgress,
    required this.xp,
    required this.xpForNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
        gradient: const LinearGradient(
          colors: [Color(0xFF141926), Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: label + level/tier badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Poin', style: AppText.caption),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0x30F97316), Color(0x20FBBF24)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FaIcon(FontAwesomeIcons.star,
                        size: 10, color: AppColors.primaryLight),
                    const SizedBox(width: 5),
                    Text(
                      'Lv.$level · $tierName',
                      style: AppText.caption.copyWith(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Big points number
          Text(
            balance.toPointsLabel,
            style: AppText.displayLarge.copyWith(
              foreground: Paint()
                ..shader = const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ).createShader(
                  const Rect.fromLTWH(0, 0, 200, 60),
                ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // XP progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'XP menuju Level ${level + 1}',
                style: AppText.caption.copyWith(fontSize: 11),
              ),
              Text(
                '${xp.toStringAsFixed(0)} / ${xpForNext.toStringAsFixed(0)} XP',
                style: AppText.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
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
                    widthFactor: xpProgress,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.gradientStart,
                            AppColors.gradientEnd,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
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
}

// ── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int streak;
  final double todayEarned;
  final int level;
  const _StatsRow(
      {required this.streak,
      required this.todayEarned,
      required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(
          icon: FontAwesomeIcons.fire,
          iconColor: AppColors.warning,
          value: '$streak',
          label: 'Hari streak',
        ),
        const SizedBox(width: AppSpacing.sm),
        _StatChip(
          icon: FontAwesomeIcons.bolt,
          iconColor: AppColors.primaryLight,
          value: todayEarned.toStringAsFixed(0),
          label: 'Poin hari ini',
        ),
        const SizedBox(width: AppSpacing.sm),
        _StatChip(
          icon: FontAwesomeIcons.star,
          iconColor: AppColors.success,
          value: 'Lv.$level',
          label: 'Level kamu',
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm + 2, horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          children: [
            FaIcon(icon, size: 14, color: iconColor),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppText.title.copyWith(fontSize: 15),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppText.caption.copyWith(fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recent badges row ────────────────────────────────────────────────────────

class _RecentBadgesRow extends StatelessWidget {
  final List<earnjoy_badge.Badge> badges;
  const _RecentBadgesRow({required this.badges});

  IconData _iconFor(String name) => switch (name) {
        'local_fire_department' => FontAwesomeIcons.fire,
        'emoji_events' => FontAwesomeIcons.trophy,
        'military_tech' => FontAwesomeIcons.medal,
        'redeem' => FontAwesomeIcons.gift,
        _ => FontAwesomeIcons.star,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pencapaian Terbaru', style: AppText.caption),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: badges.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, i) {
              final badge = badges[i];
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(
                      _iconFor(badge.icon),
                      size: 11,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      badge.name,
                      style: AppText.caption.copyWith(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Motivational quote card ──────────────────────────────────────────────────

class _MotivationalQuote extends StatelessWidget {
  final String quote;
  final String author;
  const _MotivationalQuote({required this.quote, required this.author});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x0EF97316), Color(0x06FBBF24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryDim,
              shape: BoxShape.circle,
            ),
            child: const FaIcon(
              FontAwesomeIcons.quoteLeft,
              size: 12,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quote,
                  style: AppText.body.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '— $author',
                  style: AppText.caption.copyWith(
                    color: AppColors.primary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── FAB Speed Dial ───────────────────────────────────────────────────────────

class _FabSpeedDial extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onToggle;
  final VoidCallback onQuickLog;
  final VoidCallback onLogActivity;

  const _FabSpeedDial({
    required this.isOpen,
    required this.onToggle,
    required this.onQuickLog,
    required this.onLogActivity,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Mini-button: Log Activity
        AnimatedOpacity(
          opacity: isOpen ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedSlide(
            offset: isOpen ? Offset.zero : const Offset(0, 0.4),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _MiniButton(
                label: 'Log Activity',
                icon: FontAwesomeIcons.clipboardList,
                onTap: isOpen ? onLogActivity : null,
                gradient: const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                textColor: Colors.white,
              ),
            ),
          ),
        ),

        // Mini-button: Quick Log
        AnimatedOpacity(
          opacity: isOpen ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 150),
          child: AnimatedSlide(
            offset: isOpen ? Offset.zero : const Offset(0, 0.3),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _MiniButton(
                label: 'Quick Log',
                icon: FontAwesomeIcons.bolt,
                onTap: isOpen ? onQuickLog : null,
                gradient: null,
                outlined: true,
                textColor: AppColors.primary,
              ),
            ),
          ),
        ),

        // Main FAB
        GestureDetector(
          onTap: onToggle,
          child: AnimatedRotation(
            turns: isOpen ? 0.125 : 0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final LinearGradient? gradient;
  final bool outlined;
  final Color textColor;

  const _MiniButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.gradient,
    required this.textColor,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: gradient,
          color: outlined ? AppColors.surface : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: outlined
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.5), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, size: 13, color: textColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Event banner ─────────────────────────────────────────────────────────────

class _EventBanner extends StatelessWidget {
  final GameEvent event;
  const _EventBanner({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryDim,
              shape: BoxShape.circle,
            ),
            child: const FaIcon(FontAwesomeIcons.bolt,
                color: AppColors.primary, size: 14),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚡ ${event.name}',
                  style: AppText.title
                      .copyWith(color: AppColors.primary, fontSize: 14),
                ),
                Text(event.description, style: AppText.caption),
              ],
            ),
          ),
          if (event.multiplier > 1.0) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryDim,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                '×${event.multiplier.toStringAsFixed(1)}',
                style: AppText.caption.copyWith(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Anti-Burnout Banners ─────────────────────────────────────────────────────

class _AttentionBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const FaIcon(FontAwesomeIcons.triangleExclamation,
              color: AppColors.warning, size: 16),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Pertahankan keseimbanganmu — coba variasikan aktivitas minggu ini!',
              style: AppText.caption.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

class _FatigueBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final insight =
        context.select<WellbeingProvider, String>((p) => p.balanceInsight);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FaIcon(FontAwesomeIcons.circleExclamation,
              color: AppColors.warning, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tanda-tanda kelelahan terdeteksi',
                    style: AppText.title.copyWith(
                        color: AppColors.warning, fontSize: 13)),
                const SizedBox(height: 4),
                Text(insight, style: AppText.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BurnoutInterventionBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showBurnoutDialog(context),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border:
              Border.all(color: AppColors.error.withValues(alpha: 0.40)),
        ),
        child: Row(
          children: [
            const FaIcon(FontAwesomeIcons.solidCircleXmark,
                color: AppColors.error, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kamu dalam kondisi burnout',
                      style: AppText.title.copyWith(
                          color: AppColors.error, fontSize: 14)),
                  Text(
                      'Tap untuk melihat saran & deklarasikan Hari Istirahat',
                      style: AppText.caption),
                ],
              ),
            ),
            const FaIcon(FontAwesomeIcons.chevronRight,
                color: AppColors.error, size: 14),
          ],
        ),
      ),
    );
  }

  void _showBurnoutDialog(BuildContext context) {
    final wellbeing = context.read<WellbeingProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
        ),
        title: const Text('🔴 Burnout Terdeteksi',
            style: TextStyle(color: AppColors.error, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(wellbeing.balanceInsight, style: AppText.body),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Deklarasikan Hari Istirahat untuk menjaga streakmu sambil memberi tubuh & pikiran waktu pulih.',
              style: AppText.caption,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          StatefulBuilder(
            builder: (innerCtx, setState) {
              final canDeclare = wellbeing.canDeclareRestDay;
              return ElevatedButton(
                onPressed: canDeclare
                    ? () async {
                        await wellbeing.declareRestDay();
                        if (ctx.mounted) Navigator.pop(ctx);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.surfaceHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: Text(
                  canDeclare
                      ? 'Deklarasikan Rest Day +10 pts'
                      : 'Sudah digunakan minggu ini',
                ),
              );
            },
          ),
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
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FaIcon(FontAwesomeIcons.triangleExclamation,
              color: AppColors.warning, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Burnout terdeteksi',
                    style:
                        AppText.title.copyWith(color: AppColors.warning)),
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
            child: const FaIcon(FontAwesomeIcons.xmark,
                size: 14, color: AppColors.textDisabled),
          ),
        ],
      ),
    );
  }
}

// ── Empty activities state ───────────────────────────────────────────────────

class _EmptyActivitiesState extends StatelessWidget {
  const _EmptyActivitiesState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Center(
                child: FaIcon(
                  FontAwesomeIcons.inbox,
                  color: AppColors.textDisabled,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Belum ada aktivitas hari ini',
              style: AppText.title,
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap tombol + untuk mulai mencatat\ndan kumpulkan poin!',
              style: AppText.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
