import 'package:flutter/material.dart';

import '../theme.dart';

/// Reusable full-width pill button with [AppGradients.primary] background.
/// Used as the primary CTA on each screen.
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  const GradientButton({super.key, required this.label, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.textPrimary, size: 20),
              const SizedBox(width: AppSpacing.sm),
            ],
            Text(label, style: AppText.title),
          ],
        ),
      ),
    );
  }
}
