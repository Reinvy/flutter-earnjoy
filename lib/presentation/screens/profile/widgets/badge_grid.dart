import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/presentation/providers/badge_provider.dart';
import 'package:earnjoy/data/models/badge.dart' as earnjoy_badge;

class BadgeGrid extends StatelessWidget {
  const BadgeGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BadgeProvider>(
      builder: (context, badgeProvider, child) {
        final unlocked = badgeProvider.unlockedBadges;
        final locked = badgeProvider.lockedBadges;
        final allBadges = [...unlocked, ...locked];

        if (allBadges.isEmpty) {
          return const SizedBox.shrink();
        }

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: allBadges.length,
          itemBuilder: (context, index) {
            final badge = allBadges[index];
            return _BadgeItem(badge: badge);
          },
        );
      },
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final earnjoy_badge.Badge badge;

  const _BadgeItem({required this.badge});

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'local_fire_department':
        return Icons.local_fire_department_rounded;
      case 'emoji_events':
        return Icons.emoji_events_rounded;
      case 'military_tech':
        return Icons.military_tech_rounded;
      case 'redeem':
        return Icons.redeem_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  Color _getRarityColor(int rarity) {
    switch (rarity) {
      case 1:
        return Colors.blueGrey;
      case 2:
        return Colors.blue;
      case 3:
        return AppColors.primary;
      case 4:
        return Colors.orangeAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnlocked = badge.isUnlocked;
    final color = isUnlocked ? _getRarityColor(badge.rarity) : AppColors.glassBorder;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: isUnlocked ? color.withValues(alpha: 0.15) : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: isUnlocked ? color : AppColors.glassBorder,
              width: 2,
            ),
          ),
          child: Icon(
            _getIconData(badge.icon),
            size: 32,
            color: isUnlocked ? color : AppColors.textDisabled,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          badge.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isUnlocked ? AppColors.textPrimary : AppColors.textDisabled,
          ),
        ),
      ],
    );
  }
}
