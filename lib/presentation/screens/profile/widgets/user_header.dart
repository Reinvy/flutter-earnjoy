import 'package:flutter/material.dart';

import 'package:earnjoy/core/extensions.dart';
import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/data/models/user.dart';

class UserHeader extends StatelessWidget {
  final User user;
  final double totalEarned;
  final bool editingName;
  final TextEditingController nameController;
  final VoidCallback onEditTap;
  final VoidCallback onSaveName;

  const UserHeader({
    super.key,
    required this.user,
    required this.totalEarned,
    required this.editingName,
    required this.nameController,
    required this.onEditTap,
    required this.onSaveName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar circle
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(gradient: AppGradients.primary, shape: BoxShape.circle),
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

              const SizedBox(height: 2),
              Text('${totalEarned.toPointsLabel} pts earned all-time', style: AppText.caption),
            ],
          ),
        ),
      ],
    );
  }
}
