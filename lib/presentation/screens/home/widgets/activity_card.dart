import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:earnjoy/core/extensions.dart';
import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/data/models/activity.dart';

/// Card widget for a single logged activity.
/// Features a left-accent bar colored by category, timestamp, points pill badge,
/// and an entry animation (scale pulse on first render).
class ActivityCard extends StatefulWidget {
  final Activity activity;

  const ActivityCard({super.key, required this.activity});

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _colorForCategory(String category) {
    return switch (category) {
      'Work' => AppColors.rewardEntertainment,
      'Study' => AppColors.rewardExperience,
      'Health' => AppColors.rewardSelfGrowth,
      'Hobby' => AppColors.rewardShopping,
      'Fun' => AppColors.rewardFood,
      _ => AppColors.textSecondary,
    };
  }

  IconData _iconForCategory(String category) {
    return switch (category) {
      'Work' => FontAwesomeIcons.briefcase,
      'Study' => FontAwesomeIcons.bookOpen,
      'Health' => FontAwesomeIcons.dumbbell,
      'Hobby' => FontAwesomeIcons.paintbrush,
      'Fun' => FontAwesomeIcons.gamepad,
      _ => FontAwesomeIcons.star,
    };
  }

  @override
  Widget build(BuildContext context) {
    final categoryName =
        widget.activity.category.target?.name ?? 'Unknown';
    final accentColor = _colorForCategory(categoryName);
    final isPositive = widget.activity.points >= 0;
    final timeLabel = widget.activity.createdAt.formattedTime;

    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.glassBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Left accent bar ───────────────────────────────────────
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: accentColor,
                  ),
                ),

                // ── Main content ──────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm + 2,
                    ),
                    child: Row(
                      children: [
                        // Category icon container
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Center(
                            child: FaIcon(
                              _iconForCategory(categoryName),
                              color: accentColor,
                              size: 17,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),

                        // Title + meta
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.activity.title,
                                style: AppText.title.copyWith(fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.full,
                                      ),
                                    ),
                                    child: Text(
                                      categoryName,
                                      style: AppText.caption.copyWith(
                                        color: accentColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.activity.durationMinutes
                                        .minutesToLabel,
                                    style: AppText.caption,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: AppSpacing.sm),

                        // Right side: timestamp + points badge
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              timeLabel,
                              style: AppText.caption.copyWith(fontSize: 10),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: isPositive
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF3EC193),
                                          Color(0xFF2EAF83),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : const LinearGradient(
                                        colors: [
                                          Color(0xFFEC5B5B),
                                          Color(0xFFD94444),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                '${isPositive ? '+' : ''}${widget.activity.points.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
