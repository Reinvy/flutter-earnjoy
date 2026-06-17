import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/data/models/quest.dart';
import 'package:earnjoy/presentation/providers/quest_provider.dart';

class QuestCarousel extends StatefulWidget {
  const QuestCarousel({super.key});

  @override
  State<QuestCarousel> createState() => _QuestCarouselState();
}

class _QuestCarouselState extends State<QuestCarousel> {
  StreamSubscription<List<Quest>>? _completionSub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _completionSub?.cancel();
    _completionSub = context
        .read<QuestProvider>()
        .onQuestsCompleted
        .listen(_onQuestsCompleted);
  }

  void _onQuestsCompleted(List<Quest> completed) {
    if (!mounted) return;
    final names = completed.map((q) => q.title).join(', ');
    final totalBonus =
        completed.fold<double>(0, (s, q) => s + q.bonusPoints);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: AppColors.success.withValues(alpha: 0.4)),
        ),
        content: Row(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Quest Selesai!',
                    style: AppText.title.copyWith(
                        color: AppColors.success, fontSize: 14),
                  ),
                  Text(
                    '$names · +${totalBonus.toStringAsFixed(0)} pts bonus',
                    style: AppText.caption
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
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
    _completionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quests = context.watch<QuestProvider>().dailyQuests;

    if (quests.isEmpty) {
      return const _AllQuestsDoneState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Daily Quests', style: AppText.title),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0x28F97316), Color(0x18FBBF24)],
                ),
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 0.8,
                ),
              ),
              child: Text(
                '${quests.length} aktif',
                style: AppText.caption.copyWith(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: quests.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) => _QuestCard(
            quest: quests[index],
            accentIndex: index,
          ),
        ),
      ],
    );
  }
}

// ── Quest accent colors pool ────────────────────────────────────────────────
const _questAccents = [
  Color(0xFFF97316), // amber-orange
  Color(0xFF56CFE1), // cyan
  Color(0xFF3EC193), // green
  Color(0xFFFF6B9D), // pink
  Color(0xFFB5838D), // mauve
  Color(0xFFFBBF24), // gold
];

class _QuestCard extends StatelessWidget {
  final Quest quest;
  final int accentIndex;
  const _QuestCard({required this.quest, required this.accentIndex});

  IconData _iconForTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('work') || t.contains('kerja')) {
      return FontAwesomeIcons.briefcase;
    }
    if (t.contains('study') || t.contains('belajar') || t.contains('read')) {
      return FontAwesomeIcons.bookOpen;
    }
    if (t.contains('health') ||
        t.contains('gym') ||
        t.contains('run') ||
        t.contains('olahraga')) {
      return FontAwesomeIcons.dumbbell;
    }
    if (t.contains('hobby') || t.contains('paint') || t.contains('draw')) {
      return FontAwesomeIcons.paintbrush;
    }
    if (t.contains('fun') || t.contains('game')) {
      return FontAwesomeIcons.gamepad;
    }
    return FontAwesomeIcons.bullseye;
  }

  @override
  Widget build(BuildContext context) {
    final progress = quest.progress.clamp(0.0, 1.0);
    final isNearComplete = progress >= 0.66;
    final accent = _questAccents[accentIndex % _questAccents.length];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isNearComplete
              ? accent.withValues(alpha: 0.6)
              : AppColors.glassBorder,
          width: isNearComplete ? 1.5 : 1.0,
        ),
        boxShadow: isNearComplete
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Left accent bar ───────────────────────────────────────
            Container(width: 4, color: accent),

            // ── Main content ──────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    // Quest icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Center(
                        child: FaIcon(
                          _iconForTitle(quest.title),
                          color: accent,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),

                    // Title, description, progress
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  quest.title,
                                  style: AppText.body.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _BonusChip(bonus: quest.bonusPoints),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            quest.description,
                            style: AppText.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),

                          // Progress bar + percent
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                            child: SizedBox(
                              height: 8,
                              child: Stack(
                                children: [
                                  Container(color: accent.withValues(alpha: 0.12)),
                                  FractionallySizedBox(
                                    widthFactor: progress,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            accent,
                                            accent.withValues(alpha: 0.7),
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
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                quest.description.isNotEmpty
                                    ? '${(progress * 100).toInt()}% selesai'
                                    : '${(progress * 100).toInt()}%',
                                style: AppText.caption.copyWith(
                                  color: isNearComplete
                                      ? accent
                                      : AppColors.textDisabled,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                              if (isNearComplete)
                                Row(
                                  children: [
                                    FaIcon(
                                      FontAwesomeIcons.fire,
                                      size: 9,
                                      color: accent,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Hampir selesai!',
                                      style: AppText.caption.copyWith(
                                        color: accent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BonusChip extends StatelessWidget {
  final double bonus;
  const _BonusChip({required this.bonus});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x28F97316), Color(0x18FBBF24)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Text(
        '+${bonus.toStringAsFixed(0)}',
        style: AppText.caption.copyWith(
          color: AppColors.primaryLight,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _AllQuestsDoneState extends StatelessWidget {
  const _AllQuestsDoneState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withValues(alpha: 0.08),
            AppColors.success.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 32)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Semua Quest Selesai!',
            style: AppText.title.copyWith(color: AppColors.success),
          ),
          const SizedBox(height: 4),
          const Text(
            'Quest baru tersedia besok pagi. Keep it up! 🔥',
            style: AppText.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
