import 'package:flutter/material.dart';

import '../../../core/extensions.dart';
import '../../../core/theme.dart';
import '../../../models/activity.dart';

/// Card widget for a single logged activity.
/// Animates in with a scale pulse (1.0 → 1.03 → 1.0) when first rendered.
class ActivityCard extends StatefulWidget {
  final Activity activity;

  const ActivityCard({super.key, required this.activity});

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _runScalePulse();
  }

  void _runScalePulse() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _scale = 1.03);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => _scale = 1.0);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 100),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryDim,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                _iconForCategory(widget.activity.category),
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Title + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.activity.title, style: AppText.title),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.activity.category} · ${widget.activity.durationMinutes.minutesToLabel}',
                    style: AppText.caption,
                  ),
                ],
              ),
            ),
            // Points earned
            Text(
              '+${widget.activity.points.toStringAsFixed(0)}',
              style: AppText.displaySmall.copyWith(fontSize: 20, color: AppColors.success),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Work':
        return Icons.work_outline;
      case 'Study':
        return Icons.menu_book_outlined;
      case 'Health':
        return Icons.fitness_center;
      case 'Hobby':
        return Icons.palette_outlined;
      case 'Fun':
        return Icons.sports_esports_outlined;
      default:
        return Icons.star_outline;
    }
  }
}
