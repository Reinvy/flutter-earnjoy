import 'dart:async';
import 'package:flutter/material.dart';
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
    _completionSub = context.read<QuestProvider>().onQuestsCompleted.listen(_onQuestsCompleted);
  }

  void _onQuestsCompleted(List<Quest> completed) {
    if (!mounted) return;
    final names = completed.map((q) => q.title).join(', ');
    final totalBonus = completed.fold<double>(0, (s, q) => s + q.bonusPoints);
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
                    style: AppText.title.copyWith(color: AppColors.success, fontSize: 14),
                  ),
                  Text(
                    '$names · +${totalBonus.toStringAsFixed(0)} pts bonus',
                    style: AppText.caption.copyWith(color: AppColors.textSecondary),
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
            const Text("Daily Quests", style: AppText.title),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryDim,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                '${quests.length} aktif',
                style: AppText.caption.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: quests.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) => _QuestCard(quest: quests[index]),
          ),
        ),
      ],
    );
  }
}

class _QuestCard extends StatelessWidget {
  final Quest quest;
  const _QuestCard({required this.quest});

  @override
  Widget build(BuildContext context) {
    final progress = quest.progress.clamp(0.0, 1.0);
    final isNearComplete = progress >= 0.66;

    return Container(
      width: 220,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isNearComplete
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.glassBorder,
          width: isNearComplete ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: title + bonus chip
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
              const SizedBox(width: 6),
              _BonusChip(bonus: quest.bonusPoints),
            ],
          ),
          const SizedBox(height: 6),
          // Description
          Text(
            quest.description,
            style: AppText.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          // Progress bar + percentage
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: SizedBox(
                    height: 5,
                    child: Stack(
                      children: [
                        Container(color: AppColors.primaryDim),
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: AppGradients.progressFill,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(progress * 100).toInt()}%',
                style: AppText.caption.copyWith(
                  color: isNearComplete ? AppColors.primary : AppColors.textDisabled,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x408B7FF5), Color(0x405EC4F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.primaryDim, width: 0.5),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Text('✅', style: TextStyle(fontSize: 22)),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Semua quest selesai!',
                style: AppText.body.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text('Quest baru besok pagi. Keep it up! 🔥', style: AppText.caption),
            ],
          ),
        ],
      ),
    );
  }
}
