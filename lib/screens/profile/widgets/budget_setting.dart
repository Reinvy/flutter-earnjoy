import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme.dart';
import '../../../models/user.dart';

class BudgetSetting extends StatelessWidget {
  final User user;
  final bool editing;
  final TextEditingController controller;
  final VoidCallback onEditTap;
  final VoidCallback onSave;

  const BudgetSetting({
    super.key,
    required this.user,
    required this.editing,
    required this.controller,
    required this.onEditTap,
    required this.onSave,
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 18,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Budget Cap (poin)', style: AppText.caption),
                const SizedBox(height: 2),
                if (editing)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          autofocus: true,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
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
                          onSubmitted: (_) => onSave(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      GestureDetector(
                        onTap: onSave,
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
                        Text(
                          user.monthlyBudget == 0
                              ? 'Unlimited'
                              : '${user.monthlyBudget.toStringAsFixed(0)} pts',
                          style: AppText.title,
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.edit_outlined, size: 14, color: AppColors.textDisabled),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
