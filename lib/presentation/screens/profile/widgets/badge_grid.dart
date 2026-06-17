import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

  Color _getRarityColor(int rarity) {
    switch (rarity) {
      case 1:
        return AppColors.rarityCommon;
      case 2:
        return AppColors.rarityRare;
      case 3:
        return AppColors.rarityEpic;
      case 4:
        return AppColors.rarityLegendary;
      default:
        return AppColors.textDisabled;
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
          child: Center(
            child: FaIcon(
              _getIconData(badge.icon),
              size: 28,
              color: isUnlocked ? color : AppColors.textDisabled,
            ),
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
