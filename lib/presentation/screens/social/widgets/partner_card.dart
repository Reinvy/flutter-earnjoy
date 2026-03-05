import 'package:flutter/material.dart';

import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/data/models/accountability_partner.dart';
import 'package:earnjoy/data/models/duel.dart';

class PartnerCard extends StatelessWidget {
  final AccountabilityPartner partner;
  final bool hasActiveDuel;
  final VoidCallback onDuelTap;
  final VoidCallback onRemoveTap;

  const PartnerCard({
    super.key,
    required this.partner,
    required this.hasActiveDuel,
    required this.onDuelTap,
    required this.onRemoveTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                partner.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Name & stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(partner.name, style: AppText.title),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.bolt, size: 12, color: AppColors.warning),
                    const SizedBox(width: 2),
                    Text(
                      '${partner.weeklyPoints.toStringAsFixed(0)} pts this week',
                      style: AppText.caption,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(Icons.local_fire_department, size: 12, color: AppColors.error),
                    const SizedBox(width: 2),
                    Text('${partner.streakDays} day streak', style: AppText.caption),
                  ],
                ),
              ],
            ),
          ),
          // Duel button
          if (!hasActiveDuel)
            GestureDetector(
              onTap: onDuelTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: const Text(
                  'Duel',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: onRemoveTap,
            child: Icon(Icons.close, size: 18, color: AppColors.textDisabled),
          ),
        ],
      ),
    );
  }
}

class DuelProgressCard extends StatelessWidget {
  final Duel duel;
  final String myName;
  final VoidCallback onSync;
  final VoidCallback onResolve;

  const DuelProgressCard({
    super.key,
    required this.duel,
    required this.myName,
    required this.onSync,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final total = duel.myPoints + duel.partnerPoints;
    final myFraction = total == 0 ? 0.5 : (duel.myPoints / total).clamp(0.0, 1.0);
    final partnerFraction = 1.0 - myFraction;
    final isExpired = duel.isExpired;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  isExpired ? 'EXPIRED' : '⚔️ DUEL AKTIF',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
              const Spacer(),
              if (!isExpired)
                Text(
                  '${duel.daysRemaining} hari tersisa',
                  style: AppText.caption,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // VS Row
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(myName, style: AppText.title, textAlign: TextAlign.center),
                    Text(
                      duel.myPoints.toStringAsFixed(0),
                      style: AppText.displaySmall.copyWith(
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: [AppColors.gradientStart, AppColors.gradientEnd],
                          ).createShader(const Rect.fromLTWH(0, 0, 100, 30)),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text('pts', style: AppText.caption),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text('VS', style: AppText.title.copyWith(color: AppColors.primary)),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(duel.partnerName, style: AppText.title, textAlign: TextAlign.center),
                    Text(
                      duel.partnerPoints.toStringAsFixed(0),
                      style: AppText.displaySmall.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    Text('pts', style: AppText.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(
                    flex: (myFraction * 100).round(),
                    child: Container(
                      decoration: const BoxDecoration(gradient: AppGradients.primary),
                    ),
                  ),
                  Expanded(
                    flex: (partnerFraction * 100).round(),
                    child: Container(color: AppColors.textDisabled),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSync,
                  icon: const Icon(Icons.sync, size: 16),
                  label: const Text('Sync'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withAlpha(120)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              if (isExpired) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onResolve,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Resolve'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class DuelResultCard extends StatelessWidget {
  final Duel duel;
  const DuelResultCard({super.key, required this.duel});

  @override
  Widget build(BuildContext context) {
    final isWon = duel.status == DuelStatus.userWon;
    final isDraw = duel.status == DuelStatus.draw;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isWon
              ? AppColors.success.withAlpha(120)
              : isDraw
                  ? AppColors.warning.withAlpha(120)
                  : AppColors.error.withAlpha(80),
        ),
      ),
      child: Row(
        children: [
          Text(
            isWon ? '🏆' : isDraw ? '🤝' : '💪',
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isWon
                      ? 'Kamu menang duel!'
                      : isDraw
                          ? 'Duel berakhir seri'
                          : 'Duel selesai',
                  style: AppText.title,
                ),
                Text(
                  'vs ${duel.partnerName} — ${duel.myPoints.toStringAsFixed(0)} vs ${duel.partnerPoints.toStringAsFixed(0)} pts',
                  style: AppText.caption,
                ),
                if (isWon)
                  Text('Badge "Duel Champion" diraih! 🎖️',
                      style: AppText.caption.copyWith(color: AppColors.success)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
