import 'package:flutter/foundation.dart';

import '../models/activity.dart';
import '../models/transaction.dart';
import '../services/activity_service.dart';
import '../services/point_engine.dart';
import '../services/reward_service.dart';
import '../services/storage_service.dart';
import 'user_provider.dart';

class ActivityProvider extends ChangeNotifier {
  final StorageService _storage;
  late final ActivityService _activityService;
  late final RewardService _rewardService;
  UserProvider? _userProvider;

  List<Activity> _todayActivities = [];

  ActivityProvider(this._storage) {
    _activityService = ActivityService(_storage);
    _rewardService = RewardService(_storage);
    loadTodayActivities();
  }

  List<Activity> get todayActivities => List.unmodifiable(_todayActivities);

  /// Called by [ChangeNotifierProxyProvider] each time [UserProvider] updates.
  void setUserProvider(UserProvider userProvider) {
    _userProvider = userProvider;
  }

  void loadTodayActivities() {
    _todayActivities = _activityService.getTodayActivities();
    notifyListeners();
  }

  /// Returns the earned points on success, or `null` if blocked.
  ///
  /// Blocks when:
  /// - [_userProvider] not yet injected
  /// - cooldown is active for [category]
  /// - daily point cap already reached
  double? logActivity({
    required String title,
    required String category,
    required int durationMinutes,
  }) {
    if (_userProvider == null) return null;

    // Anti-cheat: same-category cooldown
    if (_activityService.isCooldownActive(category)) return null;

    // Anti-cheat: daily cap
    final todayEarned = _storage.getTodayEarnedPoints();
    if (PointEngine.isOverDailyLimit(todayEarned)) return null;

    final user = _userProvider!.user;

    // Base calculation
    double points = PointEngine.calculatePoints(
      category: category,
      durationMinutes: durationMinutes,
      streakDays: user.streak,
      adjustmentFactor: user.adjustmentFactor,
    );

    // Diminishing returns for repeated same-category today
    final countToday = _activityService.categoryCountToday(category);
    points = PointEngine.applyDiminishingReturn(points, countToday);

    // Clamp to remaining daily cap
    points = PointEngine.clampToDailyCap(points, todayEarned);

    if (points <= 0) return null;

    // Persist activity
    _activityService.addActivity(
      title: title,
      category: category,
      durationMinutes: durationMinutes,
      points: points,
    );

    // Record earn transaction
    _storage.saveTransaction(Transaction(type: TransactionType.earn, amount: points, label: title));

    // Update user balance + streak
    _userProvider!.updateAfterActivity(points);

    // Propagate earned points to reward progress bars
    _rewardService.distributePoints(points);

    // Refresh local activity list
    _todayActivities = _activityService.getTodayActivities();
    notifyListeners();

    return points;
  }

  bool isCooldownActive(String category) => _activityService.isCooldownActive(category);

  int cooldownRemainingMinutes(String category) =>
      _activityService.cooldownRemainingMinutes(category);
}
