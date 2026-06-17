import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/data/models/badge.dart' as earnjoy_badge;

class GlobalBadgeToast {
  static void show(BuildContext context, earnjoy_badge.Badge badge) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: FaIcon(
                _getIconData(badge.icon),
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Badge Unlocked!',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    badge.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.glassBorder, width: 1),
        ),
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      ),
    );
  }

  static IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'local_fire_department':
        return FontAwesomeIcons.fire;
      case 'emoji_events':
        return FontAwesomeIcons.trophy;
      case 'military_tech':
        return FontAwesomeIcons.medal;
      case 'redeem':
        return FontAwesomeIcons.gift;
      default:
        return FontAwesomeIcons.star;
    }
  }
}
