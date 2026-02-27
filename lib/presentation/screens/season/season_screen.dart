import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/presentation/providers/season_provider.dart';
import 'package:earnjoy/presentation/providers/user_provider.dart';

class SeasonScreen extends StatelessWidget {
  const SeasonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final seasonProvider = context.watch<SeasonProvider>();
    final userProvider = context.watch<UserProvider>();
    
    // Ensure data is loaded
    if (seasonProvider.activeSeason == null) {
      seasonProvider.loadSeasonData(userProvider.user.id);
    }
    
    final activeSeason = seasonProvider.activeSeason;
    final progress = seasonProvider.userProgress;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: activeSeason == null
            ? const Center(
                child: Text('No Active Season', style: AppText.title),
              )
            : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 200,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(activeSeason.name, style: AppText.title),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: AppGradients.heroGlow,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 20),
                              Icon(Icons.military_tech_rounded, size: 64, color: AppColors.primary),
                              Text(
                                '${activeSeason.endAt.difference(DateTime.now()).inDays} days remaining',
                                style: AppText.caption,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.screenH),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SeasonProgressCard(
                            xpEarned: progress?.xpEarned ?? 0.0,
                            rank: progress?.rank ?? 0,
                          ),
                          const SizedBox(height: AppSpacing.sectionGap),
                          const Text("Season Pass Milestones", style: AppText.title),
                          const SizedBox(height: AppSpacing.md),
                          _MilestonesList(progressIndex: progress?.milestoneReached ?? -1),
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

class _SeasonProgressCard extends StatelessWidget {
  final double xpEarned;
  final int rank;

  const _SeasonProgressCard({required this.xpEarned, required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Season XP', style: AppText.body),
              Text('${xpEarned.toStringAsFixed(0)} XP', style: AppText.title),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(color: AppColors.primaryDim),
                  FractionallySizedBox(
                    widthFactor: (xpEarned % 1000) / 1000.0,
                    child: Container(
                      decoration: const BoxDecoration(gradient: AppGradients.progressFill),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Rank: $rank', style: AppText.caption),
        ],
      ),
    );
  }
}

class _MilestonesList extends StatelessWidget {
  final int progressIndex;

  const _MilestonesList({required this.progressIndex});

  @override
  Widget build(BuildContext context) {
    // Dummy milestones for visualization
    final dummyMilestones = [
      {'title': '100 XP - New Theme', 'unlocked': progressIndex >= 0},
      {'title': '500 XP - Rare Badge', 'unlocked': progressIndex >= 1},
      {'title': '1000 XP - 100 Bonus Pts', 'unlocked': progressIndex >= 2},
      {'title': '2000 XP - Season Winner Trophy', 'unlocked': progressIndex >= 3},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: dummyMilestones.length,
      itemBuilder: (context, index) {
        final item = dummyMilestones[index];
        final bool isUnlocked = item['unlocked'] as bool;
        
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isUnlocked ? AppColors.surfaceHigh : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Row(
            children: [
              Icon(
                isUnlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                color: isUnlocked ? AppColors.success : AppColors.textDisabled,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  item['title'] as String,
                  style: AppText.body.copyWith(
                    color: isUnlocked ? AppColors.textPrimary : AppColors.textDisabled,
                    fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
