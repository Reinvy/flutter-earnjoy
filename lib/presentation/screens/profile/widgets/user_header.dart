import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/core/extensions.dart';
import 'package:earnjoy/data/models/user.dart';
import 'package:earnjoy/core/utils/level_system.dart';

class UserHeader extends StatelessWidget {
  final User user;
  final double totalEarned;
  final bool editingName;
  final TextEditingController nameController;
  final VoidCallback onEditTap;
  final VoidCallback onSaveName;

  final int level;
  final String tierName;
  final double xpProgress;
  final double xpForNextLevel;

  const UserHeader({
    super.key,
    required this.user,
    required this.totalEarned,
    required this.editingName,
    required this.nameController,
    required this.onEditTap,
    required this.onSaveName,
    required this.level,
    required this.tierName,
    required this.xpProgress,
    required this.xpForNextLevel,
  });

  Color _getTierColor(String tier) => AppColors.tierColorFor(tier);

  @override
  Widget build(BuildContext context) {
    final themeColor = _getTierColor(tierName);
    final currentLevelXp = LevelSystem.xpForCurrentLevel(level);
    final nextLevelXp = LevelSystem.xpForNextLevel(level);
    final xpInCurrentLevel = user.xp - currentLevelXp;
    final requiredXpForNext = nextLevelXp - currentLevelXp;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.glassBorder),
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceHigh.withValues(alpha: 0.3),
            AppColors.surface.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Glowing Avatar Stack with level badge
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: themeColor,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: themeColor.withValues(alpha: 0.25),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppGradients.primary,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: themeColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$level',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              
              // Name & Tier details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (editingName)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: nameController,
                              autofocus: true,
                              style: AppText.title.copyWith(fontSize: 15),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 6,
                                ),
                                filled: true,
                                fillColor: AppColors.surfaceHigh,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                  borderSide: BorderSide(color: themeColor, width: 1.5),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                  borderSide: BorderSide(color: themeColor, width: 1.5),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                  borderSide: BorderSide(color: themeColor, width: 1.5),
                                ),
                              ),
                              onSubmitted: (_) => onSaveName(),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          GestureDetector(
                            onTap: onSaveName,
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: FaIcon(FontAwesomeIcons.check, color: AppColors.success, size: 18),
                            ),
                          ),
                        ],
                      )
                    else GestureDetector(
                        onTap: onEditTap,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                user.name,
                                style: AppText.displaySmall.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const FaIcon(FontAwesomeIcons.penToSquare, size: 12, color: AppColors.textDisabled),
                          ],
                        ),
                      ),
                    const SizedBox(height: 6),
                    
                    // Tier Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(color: themeColor.withValues(alpha: 0.22), width: 0.5),
                      ),
                      child: Text(
                        tierName.toUpperCase(),
                        style: TextStyle(
                          color: themeColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.solidStar, size: 9, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text(
                          'Total Poin: ${totalEarned.toPointsLabel} pts',
                          style: AppText.caption.copyWith(color: AppColors.textSecondary, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md + 4),

          // XP level progress section
          if (level < LevelSystem.maxLevel) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress Level',
                  style: AppText.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                Text(
                  '${xpInCurrentLevel.toInt()} / ${requiredXpForNext.toInt()} XP',
                  style: AppText.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: SizedBox(
                height: 8,
                child: Stack(
                  children: [
                    Container(color: AppColors.surfaceHigh),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: xpProgress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [themeColor, themeColor.withValues(alpha: 0.5)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
