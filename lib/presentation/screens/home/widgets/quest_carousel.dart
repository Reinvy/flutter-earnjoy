import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/presentation/providers/quest_provider.dart';

class QuestCarousel extends StatelessWidget {
  const QuestCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    final quests = context.watch<QuestProvider>().dailyQuests;

    if (quests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Today's Quests", style: AppText.title),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: quests.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final quest = quests[index];
              return Container(
                width: 240,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.glassBorder),
                  gradient: AppGradients.glassOverlay,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            quest.title,
                            style: AppText.title.copyWith(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDim.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text('+${quest.bonusPoints}', style: AppText.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      quest.description,
                      style: AppText.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: SizedBox(
                        height: 6,
                        child: Stack(
                          children: [
                            Container(color: AppColors.primaryDim),
                            FractionallySizedBox(
                              widthFactor: quest.progress.clamp(0.0, 1.0),
                              child: Container(
                                decoration: const BoxDecoration(gradient: AppGradients.progressFill),
                              ),
                            ),
                          ],
                        ),
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
