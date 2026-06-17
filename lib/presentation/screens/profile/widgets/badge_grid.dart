import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/presentation/providers/badge_provider.dart';
import 'package:earnjoy/data/models/badge.dart' as earnjoy_badge;

class BadgeGrid extends StatefulWidget {
  const BadgeGrid({super.key});

  @override
  State<BadgeGrid> createState() => _BadgeGridState();
}

class _BadgeGridState extends State<BadgeGrid> {
  bool _isExpanded = false;

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

        final visibleBadges = _isExpanded ? allBadges : allBadges.take(6).toList();

        return Column(
          children: [
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.82,
              ),
              itemCount: visibleBadges.length,
              itemBuilder: (context, index) {
                final badge = visibleBadges[index];
                return GestureDetector(
                  onTap: () => _showBadgeDetail(context, badge),
                  child: _BadgeItem(badge: badge),
                );
              },
            ),
            if (allBadges.length > 6) ...[
              const SizedBox(height: AppSpacing.md),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isExpanded ? 'Sembunyikan' : 'Lihat Semua',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FaIcon(
                        _isExpanded ? FontAwesomeIcons.chevronUp : FontAwesomeIcons.chevronDown,
                        size: 12,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _showBadgeDetail(BuildContext context, earnjoy_badge.Badge badge) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _BadgeDetailSheet(badge: badge);
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
    final color = isUnlocked ? _getRarityColor(badge.rarity) : AppColors.textDisabled;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isUnlocked ? color.withValues(alpha: 0.3) : AppColors.glassBorder,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isUnlocked ? color.withValues(alpha: 0.12) : AppColors.surfaceHigh,
              shape: BoxShape.circle,
              border: Border.all(
                color: isUnlocked ? color : AppColors.glassBorder,
                width: 2,
              ),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: FaIcon(
                _getIconData(badge.icon),
                size: 24,
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
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isUnlocked ? AppColors.textPrimary : AppColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeDetailSheet extends StatelessWidget {
  final earnjoy_badge.Badge badge;

  const _BadgeDetailSheet({required this.badge});

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

  String _getRarityLabel(int rarity) {
    switch (rarity) {
      case 1:
        return 'Common';
      case 2:
        return 'Rare';
      case 3:
        return 'Epic';
      case 4:
        return 'Legendary';
      default:
        return 'Unknown';
    }
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isUnlocked = badge.isUnlocked;
    final rarityColor = _getRarityColor(badge.rarity);
    final rarityLabel = _getRarityLabel(badge.rarity);
    final iconColor = isUnlocked ? rarityColor : AppColors.textDisabled;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        border: const Border(
          top: BorderSide(color: AppColors.glassBorder, width: 1.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppColors.textDisabled.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Glowing Badge Art
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer glowing sphere
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.15),
                      blurRadius: 36,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
              // Inner border circle
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: isUnlocked ? rarityColor.withValues(alpha: 0.08) : AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isUnlocked ? rarityColor : AppColors.glassBorder,
                    width: 2.5,
                  ),
                ),
                child: Center(
                  child: FaIcon(
                    _getIconData(badge.icon),
                    size: 38,
                    color: isUnlocked ? rarityColor : AppColors.textDisabled,
                  ),
                ),
              ),
              // Lock icon overlay if locked
              if (!isUnlocked)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceHigh,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.lock,
                      size: 14,
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Name and rarity label
          Text(
            badge.name,
            style: AppText.displaySmall.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Rarity Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: rarityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(
                color: rarityColor.withValues(alpha: 0.25),
                width: 0.8,
              ),
            ),
            child: Text(
              rarityLabel.toUpperCase(),
              style: TextStyle(
                color: rarityColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Divider
          Container(
            height: 1,
            color: AppColors.glassBorder,
            width: double.infinity,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Status & Description Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cara Mendapatkan',
                  style: AppText.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  badge.description,
                  style: AppText.body.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    FaIcon(
                      isUnlocked ? FontAwesomeIcons.circleCheck : FontAwesomeIcons.lock,
                      size: 16,
                      color: isUnlocked ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isUnlocked
                          ? (badge.unlockedAt != null
                              ? 'Telah Terbuka pada ${_formatDate(badge.unlockedAt!)}'
                              : 'Telah Terbuka')
                          : 'Terkunci 🔒',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Close button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.surfaceHigh,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  side: const BorderSide(color: AppColors.glassBorder),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Tutup',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
