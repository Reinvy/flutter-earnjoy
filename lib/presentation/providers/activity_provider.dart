import 'package:flutter/foundation.dart';

import 'package:earnjoy/data/models/activity.dart';
import 'package:earnjoy/data/models/transaction.dart';
import 'package:earnjoy/domain/usecases/activity_service.dart';
import 'package:earnjoy/domain/usecases/point_engine.dart';
import 'package:earnjoy/data/datasources/storage_service.dart';
import 'reward_provider.dart';
import 'user_provider.dart';

class ActivityProvider extends ChangeNotifier {
  final StorageService _storage;
  late final ActivityService _activityService;
  UserProvider? _userProvider;
  RewardProvider? _rewardProvider;

  List<Activity> _todayActivities = [];

  ActivityProvider(this._storage) {
    _activityService = ActivityService(_storage);
    loadTodayActivities();
  }

  List<Activity> get todayActivities => List.unmodifiable(_todayActivities);

  /// Called by [ChangeNotifierProxyProvider2] each time [UserProvider] updates.
  void setUserProvider(UserProvider userProvider) {
    _userProvider = userProvider;
  }

  /// Called by [ChangeNotifierProxyProvider2] each time [RewardProvider] updates.
  void setRewardProvider(RewardProvider rewardProvider) {
    _rewardProvider = rewardProvider;
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
    required int categoryId,
    required int durationMinutes,
  }) {
    if (_userProvider == null) return null;

    // Anti-cheat: same-category cooldown
    if (_activityService.isCooldownActive(categoryId)) return null;

    // Anti-cheat: daily cap
    final todayEarned = _storage.getTodayEarnedPoints();
    if (PointEngine.isOverDailyLimit(todayEarned)) return null;

    final user = _userProvider!.user;
    final category = _storage.getCategory(categoryId);
    if (category == null) return null;

    // Base calculation
    double points = PointEngine.calculatePoints(
      categoryWeight: category.weight,
      durationMinutes: durationMinutes,
      streakDays: user.streak,
      adjustmentFactor: user.adjustmentFactor,
    );

    // Diminishing returns for repeated same-category today
    final countToday = _activityService.categoryCountToday(categoryId);
    points = PointEngine.applyDiminishingReturn(points, countToday);

    // Clamp to remaining daily cap
    points = PointEngine.clampToDailyCap(points, todayEarned);

    if (points <= 0) return null;

    if (category.isNegative) {
      points = -points;
    }

    // Persist activity
    _activityService.addActivity(
      title: title,
      categoryId: categoryId,
      durationMinutes: durationMinutes,
      points: points,
    );

    // Record earn transaction
    _storage.saveTransaction(Transaction(type: TransactionType.earn, amount: points, label: title));

    // Update user balance + streak
    _userProvider!.updateAfterActivity(points);

    // Notify RewardProvider so UI reflects updated balance immediately
    _rewardProvider?.refresh();

    // Refresh local activity list
    _todayActivities = _activityService.getTodayActivities();
    notifyListeners();

    return points;
  }

  bool isCooldownActive(int categoryId) => _activityService.isCooldownActive(categoryId);

  int cooldownRemainingMinutes(int categoryId) =>
      _activityService.cooldownRemainingMinutes(categoryId);

  /// Returns the ObjectBox id for the category with [name], or `null` when not found.
  int? getCategoryIdByName(String name) {
    return _storage
        .getAllCategories()
        .where((c) => c.name.toLowerCase() == name.toLowerCase())
        .firstOrNull
        ?.id;
  }
}
