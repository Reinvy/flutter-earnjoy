import 'package:earnjoy/core/constants.dart';
import 'package:earnjoy/data/models/activity.dart';

/// Burnout status level based on 0–100 score.
enum BurnoutStatus { healthy, attention, fatigue, burnout }

/// Pure-logic service that computes a 0–100 burnout score from the
/// last 7 days of activity data using 5 weighted factors.
class BurnoutService {
  const BurnoutService();

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Computes a burnout score (0–100) from [activities] logged in the
  /// past 7 days.
  ///
  /// Factors & weights:
  ///   1. Category variety       (20%) — monotony increases score
  ///   2. Work+Study vs rest     (30%) — high productive-only ratio is bad
  ///   3. Daily cap excess       (20%) — days where poin > 80% of daily cap
  ///   4. Duration overload      (15%) — days where total duration > 8 h
  ///   5. Declining trend        (15%) — if points drop > 30% vs prior week
  double computeBurnoutScore(List<Activity> activities) {
    if (activities.isEmpty) return 0;

    final score =
        _varietyScore(activities) * 0.20 +
        _workRatioScore(activities) * 0.30 +
        _dailyCapScore(activities) * 0.20 +
        _durationScore(activities) * 0.15 +
        _trendScore(activities) * 0.15;

    return score.clamp(0.0, 100.0);
  }

  /// Returns the [BurnoutStatus] tier for a given score.
  BurnoutStatus getStatus(double score) {
    if (score <= 30) return BurnoutStatus.healthy;
    if (score <= 60) return BurnoutStatus.attention;
    if (score <= 80) return BurnoutStatus.fatigue;
    return BurnoutStatus.burnout;
  }

  /// Generates a human-readable weekly balance insight in Indonesian.
  /// [categoryDistribution] maps category name → total minutes.
  String getBalanceInsight(Map<String, double> categoryDistribution) {
    if (categoryDistribution.isEmpty) {
      return 'Belum ada aktivitas minggu ini. Mulai log aktivitasmu! 🚀';
    }

    final productiveKeys = ['Work', 'Study'];
    final restKeys = ['Health', 'Hobby', 'Fun'];

    final productiveMinutes = categoryDistribution.entries
        .where((e) => productiveKeys.contains(e.key))
        .fold(0.0, (s, e) => s + e.value);

    final restMinutes = categoryDistribution.entries
        .where((e) => restKeys.contains(e.key))
        .fold(0.0, (s, e) => s + e.value);

    final productiveHours = (productiveMinutes / 60).toStringAsFixed(1);
    final restHours = (restMinutes / 60).toStringAsFixed(1);

    final total = productiveMinutes + restMinutes;
    if (total == 0) return 'Belum ada aktivitas minggu ini. Yuk mulai log! 🚀';

    final productiveRatio = productiveMinutes / total;

    if (productiveRatio > 0.75) {
      return '📊 Minggu ini kamu log ${productiveHours}j Work & Study, tapi hanya ${restHours}j '
          'Health/Hobby. Untuk performa terbaik jangka panjang, coba tambah '
          'aktivitas olahraga atau me-time besok. Tubuh yang sehat = produktivitas '
          'yang sustainable! 💪';
    } else if (productiveRatio < 0.30 && total > 60) {
      return '📊 Minggu ini lebih banyak me-time (${restHours}j) dibanding produktif '
          '(${productiveHours}j). Pertimbangkan untuk mulai satu sesi Work atau '
          'Study hari ini—bahkan 30 menit sudah bermakna! 🎯';
    } else {
      return '📊 Balans minggu ini cukup baik! ${productiveHours}j produktif dan '
          '${restHours}j rest/hobby. Pertahankan ritme ini! ⚡';
    }
  }

  // ─── Private Factors ───────────────────────────────────────────────────────

  /// Factor 1: Category variety. Score 0–100 where 100 = only 1 category used.
  double _varietyScore(List<Activity> acts) {
    final categories = acts.map((a) => a.category.targetId).toSet();
    final totalCategories = 5; // Work, Study, Health, Hobby, Fun (excluding negative)
    final uniqueCount = categories.length.clamp(1, totalCategories);
    // 1 category = 100, 5+ categories = 0
    return ((totalCategories - uniqueCount) / (totalCategories - 1) * 100)
        .clamp(0.0, 100.0);
  }

  /// Factor 2: Work+Study vs Health/Hobby/Fun duration ratio.
  /// Ideal: productive ≤ 60%. If > 80%, score spikes.
  double _workRatioScore(List<Activity> acts) {
    const productiveNames = {'Work', 'Study'};
    double productive = 0, total = 0;
    for (final a in acts) {
      final name = a.category.target?.name ?? '';
      if (!a.category.target!.isNegative) {
        total += a.durationMinutes;
        if (productiveNames.contains(name)) productive += a.durationMinutes;
      }
    }
    if (total == 0) return 0;
    final ratio = productive / total;
    if (ratio <= 0.60) return 0;
    if (ratio >= 0.90) return 100;
    return ((ratio - 0.60) / 0.30 * 100).clamp(0.0, 100.0);
  }

  /// Factor 3: Days where earned points exceeded 80% of daily cap.
  double _dailyCapScore(List<Activity> acts) {
    final byDay = _groupByDay(acts);
    int overDays = 0;
    for (final dayActs in byDay.values) {
      final total = dayActs.fold(0.0, (s, a) => s + a.points.abs());
      if (total > maxPointsPerDay * 0.80) overDays++;
    }
    if (byDay.isEmpty) return 0;
    return (overDays / byDay.length * 100).clamp(0.0, 100.0);
  }

  /// Factor 4: Days with total activity duration > 8 hours (480 min).
  double _durationScore(List<Activity> acts) {
    final byDay = _groupByDay(acts);
    int overloadDays = 0;
    for (final dayActs in byDay.values) {
      final totalMinutes = dayActs.fold(0, (s, a) => s + a.durationMinutes);
      if (totalMinutes > 480) overloadDays++;
    }
    if (byDay.isEmpty) return 0;
    return (overloadDays / byDay.length * 100).clamp(0.0, 100.0);
  }

  /// Factor 5: Declining trend — compare total points of first 3 days vs last 3 days.
  /// If last 3 days earned < 70% of first 3, score = 100.
  double _trendScore(List<Activity> acts) {
    final sorted = List<Activity>.from(acts)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    if (sorted.length < 4) return 0;

    final half = sorted.length ~/ 2;
    final firstHalf = sorted.take(half).toList();
    final secondHalf = sorted.skip(sorted.length - half).toList();

    final firstPts = firstHalf.fold(0.0, (s, a) => s + a.points.abs());
    final secondPts = secondHalf.fold(0.0, (s, a) => s + a.points.abs());

    if (firstPts == 0) return 0;
    final ratio = secondPts / firstPts;
    if (ratio >= 0.70) return 0;
    if (ratio <= 0.30) return 100;
    return ((0.70 - ratio) / 0.40 * 100).clamp(0.0, 100.0);
  }

  /// Groups activities by calendar day key.
  Map<String, List<Activity>> _groupByDay(List<Activity> acts) {
    final Map<String, List<Activity>> result = {};
    for (final a in acts) {
      final key = '${a.createdAt.year}-${a.createdAt.month}-${a.createdAt.day}';
      result.putIfAbsent(key, () => []).add(a);
    }
    return result;
  }
}
