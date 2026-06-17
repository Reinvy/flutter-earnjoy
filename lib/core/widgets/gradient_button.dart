import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../theme.dart';

/// Reusable full-width pill button with [AppGradients.primary] background.
/// Pass `onTap: null` to render in a disabled/dimmed state.
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  const GradientButton({super.key, required this.label, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.45,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                FaIcon(icon, color: AppColors.textPrimary, size: 16),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label, style: AppText.title),
            ],
          ),
        ),
      ),
    );
  }
}
