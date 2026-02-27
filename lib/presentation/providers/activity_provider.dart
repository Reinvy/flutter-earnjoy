import 'package:flutter/foundation.dart' hide Category;

import 'package:earnjoy/data/models/activity.dart';
import 'package:earnjoy/data/models/activity_preset.dart';
import 'package:earnjoy/data/models/category.dart';
import 'package:earnjoy/data/models/transaction.dart';
import 'package:earnjoy/domain/usecases/activity_service.dart';
import 'package:earnjoy/domain/usecases/point_engine.dart';
import 'package:earnjoy/data/datasources/storage_service.dart';
import 'reward_provider.dart';
import 'user_provider.dart';
import 'quest_provider.dart';
import 'badge_provider.dart';
import 'event_provider.dart';

class ActivityProvider extends ChangeNotifier {
  final StorageService _storage;
  late final ActivityService _activityService;
  UserProvider? _userProvider;
  RewardProvider? _rewardProvider;
  QuestProvider? _questProvider;
  BadgeProvider? _badgeProvider;
  EventProvider? _eventProvider;

  List<Activity> _todayActivities = [];
  List<ActivityPreset> _presets = [];
  List<Category> _categories = [];

  ActivityProvider(this._storage) {
    _activityService = ActivityService(_storage);
    loadTodayActivities();
    loadPresets();
    loadCategories();
  }

  List<Activity> get todayActivities => List.unmodifiable(_todayActivities);
  List<ActivityPreset> get presets => List.unmodifiable(_presets);
  List<Category> get categories => List.unmodifiable(_categories);

  /// Called by [ChangeNotifierProxyProvider2] each time [UserProvider] updates.
  void setUserProvider(UserProvider userProvider) {
    _userProvider = userProvider;
  }

  /// Called by [ChangeNotifierProxyProvider2] each time [RewardProvider] updates.
  void setRewardProvider(RewardProvider rewardProvider) {
    _rewardProvider = rewardProvider;
  }

  void setQuestProvider(QuestProvider questProvider) {
    _questProvider = questProvider;
  }

  void setBadgeProvider(BadgeProvider badgeProvider) {
    _badgeProvider = badgeProvider;
  }

  void setEventProvider(EventProvider eventProvider) {
    _eventProvider = eventProvider;
  }

  void loadTodayActivities() {
    _todayActivities = _activityService.getTodayActivities();
    notifyListeners();
  }

  void loadPresets() {
    _presets = _storage.getAllActivityPresets();
    notifyListeners();
  }

  void loadCategories() {
    _categories = _storage.getAllCategories();
    notifyListeners();
  }

  // ─── Activity Logging ──────────────────────────────────────────────────────

  /// Returns the earned points on success, or `null` if blocked.
  ///
  /// No longer blocks for same-category. Repeated same-category logs today
  /// automatically receive diminishing returns (penalty) from [PointEngine].
  double? logActivity({
    required String title,
    required int categoryId,
    required int durationMinutes,
  }) {
    if (_userProvider == null) return null;

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

    // Apply level multiplier
    points *= _userProvider!.pointMultiplier;

    // Apply event multiplier
    final eventMultiplier = _eventProvider?.getMultiplierForCategory(categoryId) ?? 1.0;
    points *= eventMultiplier;

    // Penalty: diminishing returns for repeated same-category today
    final countToday = _activityService.categoryCountToday(categoryId);
    points = PointEngine.applyDiminishingReturn(points, countToday);

    // Clamp to remaining daily cap
    points = PointEngine.clampToDailyCap(points, todayEarned);

    if (points <= 0) return null;

    if (category.isNegative) {
      points = -points;
    }

    // Persist activity
    final createdActivity = _activityService.addActivity(
      title: title,
      categoryId: categoryId,
      durationMinutes: durationMinutes,
      points: points,
    );

    // Record earn transaction
    _storage.saveTransaction(Transaction(type: TransactionType.earn, amount: points, label: title));

    // Update quests
    _questProvider?.onActivityLogged(createdActivity);

    // Update user balance + streak
    _userProvider!.updateAfterActivity(points);

    // Evaluate badges
    _badgeProvider?.evaluateActivity(createdActivity);
    _badgeProvider?.evaluateStreak(_userProvider!.user);

    // Notify RewardProvider so UI reflects updated balance immediately
    _rewardProvider?.refresh();

    // Refresh local activity list
    _todayActivities = _activityService.getTodayActivities();
    notifyListeners();

    return points;
  }

  /// How many penalty steps applied for [categoryId] today (0 = full points).
  int penaltyCountForCategory(int categoryId) => _activityService.categoryCountToday(categoryId);

  // ─── ActivityPreset CRUD ──────────────────────────────────────────────────

  ActivityPreset addPreset({
    required String title,
    required int categoryId,
    required int durationMinutes,
  }) {
    final category = _storage.getCategory(categoryId);
    final preset = ActivityPreset(title: title, durationMinutes: durationMinutes, isDefault: false);
    preset.category.target = category;
    _storage.saveActivityPreset(preset);
    _presets = _storage.getAllActivityPresets();
    notifyListeners();
    return preset;
  }

  bool deletePreset(int id) {
    final result = _storage.deleteActivityPreset(id);
    if (result) {
      _presets = _storage.getAllActivityPresets();
      notifyListeners();
    }
    return result;
  }

  // ─── Category CRUD ────────────────────────────────────────────────────────

  Category addCategory({
    required String name,
    required double weight,
    required bool isNegative,
    required String icon,
  }) {
    final category = Category(name: name, weight: weight, isNegative: isNegative, icon: icon);
    _storage.saveCategory(category);
    _categories = _storage.getAllCategories();
    notifyListeners();
    return category;
  }

  void updateCategory(Category updated) {
    _storage.saveCategory(updated);
    _categories = _storage.getAllCategories();
    notifyListeners();
  }

  /// Delete category and all linked presets.
  bool deleteCategory(int id) {
    final linkedPresets = _presets.where((p) => p.category.targetId == id).toList();
    for (final p in linkedPresets) {
      _storage.deleteActivityPreset(p.id);
    }
    final result = _storage.deleteCategory(id);
    if (result) {
      _categories = _storage.getAllCategories();
      _presets = _storage.getAllActivityPresets();
      notifyListeners();
    }
    return result;
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  /// Returns the ObjectBox id for the category with [name], or `null` when not found.
  int? getCategoryIdByName(String name) {
    return _storage
        .getAllCategories()
        .where((c) => c.name.toLowerCase() == name.toLowerCase())
        .firstOrNull
        ?.id;
  }
}
