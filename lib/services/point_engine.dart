import '../core/constants.dart';

/// Pure Dart — no Flutter imports, no ObjectBox imports.
/// Contains all point calculation logic.
class PointEngine {
  /// Full formula:
  ///   points = durationMinutes * categoryWeight * streakBonus * adjustmentFactor
  static double calculatePoints({
    required String category,
    required int durationMinutes,
    required int streakDays,
    double adjustmentFactor = 1.0,
  }) {
    final weight = categoryWeights[category] ?? 1.0;
    final bonus = calculateStreakBonus(streakDays);
    return durationMinutes * weight * bonus * adjustmentFactor;
  }

  /// Streak bonus: 1 + (streakDays * 0.05)
  static double calculateStreakBonus(int streakDays) {
    return 1.0 + (streakDays * 0.05);
  }

  /// Diminishing returns for repeated same-category activities.
  /// Each additional log today reduces points by [diminishingReturnFactor].
  /// [countToday] = number of times this category was already logged today (0-based).
  static double applyDiminishingReturn(double points, int countToday) {
    if (countToday <= 0) return points;
    return points * _pow(diminishingReturnFactor, countToday);
  }

  /// Whether the user has already hit the daily point cap.
  static bool isOverDailyLimit(double currentDailyPoints) {
    return currentDailyPoints >= maxPointsPerDay;
  }

  /// How many more points the user can earn today before hitting the cap.
  static double remainingDailyCapacity(double currentDailyPoints) {
    final remaining = maxPointsPerDay - currentDailyPoints;
    return remaining < 0 ? 0 : remaining;
  }

  /// Clamp earned points to not exceed the remaining daily cap.
  static double clampToDailyCap(double points, double currentDailyPoints) {
    final remaining = remainingDailyCapacity(currentDailyPoints);
    return points > remaining ? remaining : points;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static double _pow(double base, int exp) {
    double result = 1.0;
    for (int i = 0; i < exp; i++) {
      result *= base;
    }
    return result;
  }
}
