import 'package:flutter/foundation.dart';
import 'package:earnjoy/data/datasources/storage_service.dart';
import 'package:earnjoy/data/models/streak_record.dart';

/// Period filter options for analytics panels.
enum InsightsPeriod { week, month, allTime }

class InsightsProvider extends ChangeNotifier {
  final StorageService _storage;

  InsightsPeriod _period = InsightsPeriod.month;
  int _trendDays = 30;

  // ─── Computed state ─────────────────────────────────────────────────────────
  Map<DateTime, double> _heatmapData = {};
  List<Map<String, dynamic>> _trendData = [];
  Map<String, double> _categoryDistribution = {};
  Map<int, double> _hourlyProductivity = {};
  List<StreakRecord> _streakHistory = [];
  Map<DateTime, Map<String, double>> _goalVsActual = {};
  double _dailyPointTarget = 300.0;

  InsightsProvider(this._storage) {
    refresh();
  }

  // ─── Getters ─────────────────────────────────────────────────────────────────
  InsightsPeriod get period => _period;
  int get trendDays => _trendDays;
  Map<DateTime, double> get heatmapData => _heatmapData;
  List<Map<String, dynamic>> get trendData => _trendData;
  Map<String, double> get categoryDistribution => _categoryDistribution;
  Map<int, double> get hourlyProductivity => _hourlyProductivity;
  List<StreakRecord> get streakHistory => _streakHistory;
  Map<DateTime, Map<String, double>> get goalVsActual => _goalVsActual;
  double get dailyPointTarget => _dailyPointTarget;

  /// Personal record: longest streak ever.
  StreakRecord? get personalRecord {
    if (_streakHistory.isEmpty) return null;
    return _streakHistory.reduce((a, b) => a.days >= b.days ? a : b);
  }

  /// Current active streak (streak ending today or yesterday).
  StreakRecord? get currentStreak {
    if (_streakHistory.isEmpty) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final latest = _streakHistory.first;
    final end = DateTime(latest.endDate.year, latest.endDate.month, latest.endDate.day);
    if (end == today || end == yesterday) return latest;
    return null;
  }

  /// Percentage of days where actual >= target in [_goalVsActual].
  double get goalAchievementRate {
    if (_goalVsActual.isEmpty) return 0.0;
    final achieved = _goalVsActual.values.where((v) => (v['actual'] ?? 0) >= (v['target'] ?? 1)).length;
    return achieved / _goalVsActual.length;
  }

  /// Total hours logged in the current period.
  double get totalHoursLogged {
    final total = _categoryDistribution.values.fold(0.0, (sum, v) => sum + v);
    return total / 60.0;
  }

  /// Identify player's "golden hour" (peak productivity hour).
  int? get goldenHour {
    if (_hourlyProductivity.isEmpty) return null;
    return _hourlyProductivity.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  // ─── Actions ──────────────────────────────────────────────────────────────────

  void setPeriod(InsightsPeriod p) {
    _period = p;
    switch (p) {
      case InsightsPeriod.week:
        _trendDays = 7;
        break;
      case InsightsPeriod.month:
        _trendDays = 30;
        break;
      case InsightsPeriod.allTime:
        _trendDays = 90;
        break;
    }
    refresh();
  }

  void setDailyTarget(double target) {
    _storage.setDailyPointTarget(target);
    _dailyPointTarget = target.clamp(50.0, 5000.0);
    _goalVsActual = _storage.getGoalVsActual(days: 28);
    notifyListeners();
  }

  void refresh() {
    final periodKey = _period == InsightsPeriod.week
        ? 'week'
        : _period == InsightsPeriod.month
            ? 'month'
            : 'all';

    _heatmapData = _storage.getHeatmapData();
    _trendData = _storage.getPointTrendByDay(_trendDays);
    _categoryDistribution = _storage.getCategoryDistribution(periodKey);
    _hourlyProductivity = _storage.getHourlyProductivity();
    _streakHistory = _storage.getStreakHistory();
    _goalVsActual = _storage.getGoalVsActual(days: 28);
    _dailyPointTarget = _storage.getUser().dailyPointTarget;
    notifyListeners();
  }
}
