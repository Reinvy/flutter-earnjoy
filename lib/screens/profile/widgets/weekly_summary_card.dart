import 'package:flutter/material.dart';

import '../../../core/theme.dart';

class WeeklySummaryCard extends StatelessWidget {
  final int activitiesCount;
  final double pointsEarned;
  final int redeemedCount;

  const WeeklySummaryCard({
    super.key,
    required this.activitiesCount,
    required this.pointsEarned,
    required this.redeemedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          _StatItem(
            label: 'Activities',
            value: '$activitiesCount',
            icon: Icons.directions_run,
            color: AppColors.primary,
          ),
          _VerticalDivider(),
          _StatItem(
            label: 'Points',
            value: pointsEarned >= 1000
                ? '${(pointsEarned / 1000).toStringAsFixed(1)}k'
                : pointsEarned.toStringAsFixed(0),
            icon: Icons.star_outline,
            color: AppColors.warning,
          ),
          _VerticalDivider(),
          _StatItem(
            label: 'Redeemed',
            value: '$redeemedCount',
            icon: Icons.redeem,
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.glassBorder,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppText.displaySmall.copyWith(fontSize: 22, color: AppColors.textPrimary),
          ),
          Text(label, style: AppText.caption),
        ],
      ),
    );
  }
}
