import 'package:flutter/material.dart';

import 'package:earnjoy/core/theme.dart';
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

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'Novice':
        return Colors.grey.shade400;
      case 'Apprentice':
        return Colors.blue.shade400;
      case 'Practitioner':
        return Colors.green.shade500;
      case 'Achiever':
        return Colors.orange.shade500;
      case 'Expert':
        return Colors.purple.shade400;
      case 'Master':
        return Colors.red.shade500;
      case 'Legend':
        return Colors.amber.shade500;
      default:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar circle with Tier border
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            shape: BoxShape.circle,
            border: Border.all(
              color: _getTierColor(tierName),
              width: 3.0,
            ),
          ),
          child: Center(
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(width: AppSpacing.md),

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
                        style: AppText.title,
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
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                        onSubmitted: (_) => onSaveName(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    GestureDetector(
                      onTap: onSaveName,
                      child: const Icon(Icons.check, color: AppColors.success, size: 22),
                    ),
                  ],
                )
              else
                GestureDetector(
                  onTap: onEditTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(user.name, style: AppText.title),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit_outlined, size: 14, color: AppColors.textDisabled),
                    ],
                  ),
                ),

              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Lvl $level • $tierName', style: AppText.caption.copyWith(color: _getTierColor(tierName), fontWeight: FontWeight.bold)),
                  if (level < LevelSystem.maxLevel)
                    Text('${(xpProgress * 100).toInt()}%', style: AppText.caption.copyWith(fontSize: 10)),
                ],
              ),
              const SizedBox(height: 4),
              // Progress Bar
              if (level < LevelSystem.maxLevel)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: xpProgress,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(_getTierColor(tierName)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
