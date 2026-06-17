import 'dart:convert';
import 'package:earnjoy/data/datasources/storage_service.dart';
import 'package:earnjoy/data/models/activity.dart';
import 'package:earnjoy/data/models/badge.dart';

class BadgeService {
  final StorageService _storage;

  BadgeService(this._storage);

  /// Ensure default badges are in the database.
  void ensureDefaultBadges() {
    final existing = _storage.getAllBadges().map((b) => b.badgeKey).toSet();

    final defaultBadges = [
      // ─── STREAK BADGES ──────────────────────────────────────────────────
      Badge(
        badgeKey: 'streak_3',
        name: 'First Spark',
        description: 'Streak 3 hari pertama',
        icon: 'local_fire_department',
        category: 'streak',
        rarity: 1,
        conditionJson: jsonEncode({'type': 'streak', 'target': 3}),
      ),
      Badge(
        badgeKey: 'streak_7',
        name: 'Week Warrior',
        description: 'Streak 7 hari',
        icon: 'local_fire_department',
        category: 'streak',
        rarity: 2,
        conditionJson: jsonEncode({'type': 'streak', 'target': 7}),
      ),
      Badge(
        badgeKey: 'streak_30',
        name: 'Month Legend',
        description: 'Streak 30 hari',
        icon: 'local_fire_department',
        category: 'streak',
        rarity: 3,
        conditionJson: jsonEncode({'type': 'streak', 'target': 30}),
      ),

      // ─── VOLUME BADGES ──────────────────────────────────────────────────
      Badge(
        badgeKey: 'first_step',
        name: 'First Step',
        description: 'Log aktivitas pertama',
        icon: 'emoji_events',
        category: 'volume',
        rarity: 1,
        conditionJson: jsonEncode({'type': 'log_count', 'target': 1}),
      ),
      Badge(
        badgeKey: 'centurion',
        name: 'Centurion',
        description: 'Total 100 aktivitas dilog',
        icon: 'military_tech',
        category: 'volume',
        rarity: 2,
        conditionJson: jsonEncode({'type': 'log_count', 'target': 100}),
      ),

      // ─── REDEEM BADGES ──────────────────────────────────────────────────
      Badge(
        badgeKey: 'first_taste',
        name: 'First Taste',
        description: 'Redeem reward pertama',
        icon: 'redeem',
        category: 'redeem',
        rarity: 1,
        conditionJson: jsonEncode({'type': 'redeem_count', 'target': 1}),
      ),
      Badge(
        badgeKey: 'collector',
        name: 'Collector',
        description: 'Redeem 10 reward',
        icon: 'redeem',
        category: 'redeem',
        rarity: 2,
        conditionJson: jsonEncode({'type': 'redeem_count', 'target': 10}),
      ),

      // ─── SOCIAL BADGES ──────────────────────────────────────────────────
      Badge(
        badgeKey: 'duel_champion',
        name: 'Duel Champion',
        description: 'Menangkan Weekly Duel melawan seorang partner',
        icon: 'emoji_events',
        category: 'social',
        rarity: 3, // Epic
        conditionJson: jsonEncode({'type': 'manual', 'key': 'duel_champion'}),
      ),
    ];

    for (final b in defaultBadges) {
      if (!existing.contains(b.badgeKey)) {
        _storage.saveBadge(b);
      }
    }
  }

  /// Evaluates badges based on freshly logged activity
  List<Badge> evaluateActivity(Activity activity) {
    List<Badge> newlyUnlocked = [];

    // Evaluate volume badges (log_count)
    final allActivitiesCount = _storage.getAllActivities().length;
    final lockedBadges = _storage.getAllBadges().where((b) => !b.isUnlocked).toList();

    for (final badge in lockedBadges) {
      final condition = jsonDecode(badge.conditionJson) as Map<String, dynamic>;
      if (condition['type'] == 'log_count') {
        final target = condition['target'] as int;
        if (allActivitiesCount >= target) {
          badge.isUnlocked = true;
          badge.unlockedAt = DateTime.now();
          _storage.saveBadge(badge);
          newlyUnlocked.add(badge);
        }
      }
    }

    // You can also add Category Master evaluation here
    return newlyUnlocked;
  }

  /// Evaluates streak-based badges
  List<Badge> evaluateStreak(int currentStreak) {
    List<Badge> newlyUnlocked = [];
    final lockedBadges = _storage.getAllBadges().where((b) => !b.isUnlocked).toList();

    for (final badge in lockedBadges) {
      final condition = jsonDecode(badge.conditionJson) as Map<String, dynamic>;
      if (condition['type'] == 'streak') {
        final target = condition['target'] as int;
        if (currentStreak >= target) {
          badge.isUnlocked = true;
          badge.unlockedAt = DateTime.now();
          _storage.saveBadge(badge);
          newlyUnlocked.add(badge);
        }
      }
    }
    return newlyUnlocked;
  }

  /// Evaluates redeem-based badges
  List<Badge> evaluateRedeemAmount(int rewardCost) {
    List<Badge> newlyUnlocked = [];
    // Calculate total times redeemed if needed, or total points spent.
    // For simplicity, we just count the total 'redeem' transactions.
    final totalRedeems = _storage.getAllTransactions().where((t) => t.isRedeem).length;

    final lockedBadges = _storage.getAllBadges().where((b) => !b.isUnlocked).toList();

    for (final badge in lockedBadges) {
      final condition = jsonDecode(badge.conditionJson) as Map<String, dynamic>;
      if (condition['type'] == 'redeem_count') {
        final target = condition['target'] as int;
        if (totalRedeems >= target) {
          badge.isUnlocked = true;
          badge.unlockedAt = DateTime.now();
          _storage.saveBadge(badge);
          newlyUnlocked.add(badge);
        }
      }
    }
    return newlyUnlocked;
  }
}
