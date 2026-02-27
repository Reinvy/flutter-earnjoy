import 'dart:convert';

import 'package:earnjoy/data/models/activity.dart';
import 'package:earnjoy/data/models/activity_preset.dart';
import 'package:earnjoy/data/models/reward.dart';
import 'package:earnjoy/data/models/transaction.dart';
import 'package:earnjoy/data/models/user.dart';
import 'package:earnjoy/data/models/category.dart';
import 'package:earnjoy/data/models/quest.dart';
import 'package:earnjoy/data/models/badge.dart';
import 'package:earnjoy/data/models/season.dart';
import 'package:earnjoy/data/models/season_progress.dart';
import 'package:earnjoy/data/models/game_event.dart';
import 'package:earnjoy/data/models/habit_stack.dart';
import 'package:earnjoy/data/models/stack_item.dart';
import 'package:earnjoy/objectbox.g.dart';

/// The single layer that knows about ObjectBox.
/// All other services depend on this - never import objectbox directly elsewhere.
class StorageService {
  late final Store _store;

  Future<void> init() async {
    _store = await openStore();
    _seedUserIfEmpty();
    _seedCategoriesIfEmpty();
    _seedActivityPresetsIfEmpty();
    _seedSeasonAndEventsIfEmpty();
    _seedHabitStacksIfEmpty();
  }

  Store get store => _store;

  Box<User> get _userBox => _store.box<User>();
  Box<Activity> get _activityBox => _store.box<Activity>();
  Box<Reward> get _rewardBox => _store.box<Reward>();
  Box<Transaction> get _transactionBox => _store.box<Transaction>();
  Box<Category> get _categoryBox => _store.box<Category>();
  Box<Quest> get _questBox => _store.box<Quest>();
  Box<Badge> get _badgeBox => _store.box<Badge>();
  Box<ActivityPreset> get _presetBox => _store.box<ActivityPreset>();
  Box<HabitStack> get _habitStackBox => _store.box<HabitStack>();
  Box<StackItem> get _stackItemBox => _store.box<StackItem>();
  Box<Season> get _seasonBox => _store.box<Season>();
  Box<SeasonProgress> get _seasonProgressBox => _store.box<SeasonProgress>();
  Box<GameEvent> get _eventBox => _store.box<GameEvent>();

  /// Returns the single app user (id=1), creating a default one if absent.
  User getUser() {
    final user = _userBox.get(1);
    return user ?? _createDefaultUser();
  }

  int saveUser(User user) => _userBox.put(user);

  User _createDefaultUser() {
    final user = User(id: 0); // 0 = let ObjectBox auto-assign (will become 1)
    _userBox.put(user);
    return user;
  }

  void _seedUserIfEmpty() {
    if (_userBox.get(1) == null) _createDefaultUser();
  }

  void _seedCategoriesIfEmpty() {
    if (_categoryBox.count() > 0) return;
    const defaults = [
      {'name': 'Work', 'weight': 1.3, 'isNegative': false, 'icon': 'work'},
      {'name': 'Study', 'weight': 1.2, 'isNegative': false, 'icon': 'menu_book'},
      {'name': 'Health', 'weight': 1.1, 'isNegative': false, 'icon': 'fitness_center'},
      {'name': 'Hobby', 'weight': 0.8, 'isNegative': false, 'icon': 'palette'},
      {'name': 'Fun', 'weight': 0.5, 'isNegative': false, 'icon': 'sports_esports'},
      {'name': 'Doomscroll', 'weight': 1.0, 'isNegative': true, 'icon': 'phone_android'},
    ];
    for (final d in defaults) {
      _categoryBox.put(
        Category(
          name: d['name'] as String,
          weight: d['weight'] as double,
          isNegative: d['isNegative'] as bool,
          icon: d['icon'] as String,
        ),
      );
    }
  }

  void _seedActivityPresetsIfEmpty() {
    if (_presetBox.count() > 0) return;
    // Map category name → default presets
    const defaults = [
      {'title': 'Study Session', 'category': 'Study', 'duration': 30},
      {'title': 'Deep Work', 'category': 'Work', 'duration': 60},
      {'title': 'Workout / Gym', 'category': 'Health', 'duration': 45},
      {'title': 'Reading', 'category': 'Hobby', 'duration': 30},
      {'title': 'Morning Run', 'category': 'Health', 'duration': 30},
      {'title': 'Creative Project', 'category': 'Hobby', 'duration': 60},
      {'title': 'Online Course', 'category': 'Study', 'duration': 45},
      {'title': 'Game / Fun Time', 'category': 'Fun', 'duration': 30},
      {'title': 'Doomscrolling', 'category': 'Doomscroll', 'duration': 30},
    ];
    final categories = getAllCategories();
    for (final d in defaults) {
      final cat = categories.where((c) => c.name == d['category']).firstOrNull;
      if (cat == null) continue;
      final preset = ActivityPreset(
        title: d['title'] as String,
        durationMinutes: d['duration'] as int,
        isDefault: true,
      );
      preset.category.target = cat;
      _presetBox.put(preset);
    }
  }

  void _seedHabitStacksIfEmpty() {
    if (_habitStackBox.count() > 0) return;

    final categories = getAllCategories();
    final healthCat = categories.where((c) => c.name == 'Health').firstOrNull;
    final hobbyCat = categories.where((c) => c.name == 'Hobby').firstOrNull;
    final workCat = categories.where((c) => c.name == 'Work').firstOrNull;
    final studyCat = categories.where((c) => c.name == 'Study').firstOrNull;

    // Morning Kickstart
    final morningStack = HabitStack(
      name: 'Morning Kickstart',
      description: 'Start your day with energy and focus',
      isTemplate: true,
      bonusPoints: 50,
    );

    if (healthCat != null && hobbyCat != null) {
      final morningItem1 = StackItem(
        activityTitle: 'Morning Workout/Run',
        durationMinutes: 20,
        order: 1,
      );
      morningItem1.category.target = healthCat;

      final morningItem2 = StackItem(
        activityTitle: 'Journaling',
        durationMinutes: 10,
        order: 2,
      );
      morningItem2.category.target = hobbyCat;

      final morningItem3 = StackItem(
        activityTitle: 'Reading/Planning',
        durationMinutes: 30,
        order: 3,
      );
      morningItem3.category.target = hobbyCat;

      morningStack.items.addAll([morningItem1, morningItem2, morningItem3]);
      _habitStackBox.put(morningStack);
    }

    // Deep Work Session
    final deepWorkStack = HabitStack(
      name: 'Deep Work Session',
      description: 'Focus without distractions',
      isTemplate: true,
      bonusPoints: 75,
    );

    if (workCat != null) {
      final dsItem1 = StackItem(
        activityTitle: 'Deep Work Block 1',
        durationMinutes: 45,
        order: 1,
      );
      dsItem1.category.target = workCat;

      final dsItem2 = StackItem(
        activityTitle: 'Deep Work Block 2',
        durationMinutes: 45,
        order: 2,
      );
      dsItem2.category.target = workCat;

      deepWorkStack.items.addAll([dsItem1, dsItem2]);
      _habitStackBox.put(deepWorkStack);
    }

    // Student Power Block
    final studentStack = HabitStack(
      name: 'Student Power Block',
      description: 'Maximize your study efficiency',
      isTemplate: true,
      bonusPoints: 60,
    );

    if (studyCat != null) {
      final spItem1 = StackItem(
        activityTitle: 'Pomodoro Study 1',
        durationMinutes: 25,
        order: 1,
      );
      spItem1.category.target = studyCat;

      final spItem2 = StackItem(
        activityTitle: 'Pomodoro Study 2',
        durationMinutes: 25,
        order: 2,
      );
      spItem2.category.target = studyCat;

      final spItem3 = StackItem(
        activityTitle: 'Pomodoro Study 3',
        durationMinutes: 25,
        order: 3,
      );
      spItem3.category.target = studyCat;

      studentStack.items.addAll([spItem1, spItem2, spItem3]);
      _habitStackBox.put(studentStack);
    }
  }

  void _seedSeasonAndEventsIfEmpty() {
    if (_seasonBox.count() == 0) {
      _seasonBox.put(Season(
        name: 'Season 1: Kebangkitan',
        themeKey: 'cosmic',
        startAt: DateTime.now().subtract(const Duration(days: 5)),
        endAt: DateTime.now().add(const Duration(days: 85)),
        isActive: true,
      ));
    }
    
    if (_eventBox.count() == 0) {
      _eventBox.put(GameEvent(
        name: '🔥 Double XP Weekend',
        description: 'Semua aktivitas mendapatkan +100% XP bonus!',
        type: 'double_xp',
        multiplier: 2.0,
        startAt: DateTime.now().subtract(const Duration(hours: 2)),
        endAt: DateTime.now().add(const Duration(days: 2)),
        isActive: true,
      ));
    }
  }

  int saveActivity(Activity activity) => _activityBox.put(activity);

  List<Activity> getAllActivities() =>
      _activityBox.getAll()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Activity> getTodayActivities() {
    final now = DateTime.now();
    return getAllActivities().where((a) {
      return a.createdAt.year == now.year &&
          a.createdAt.month == now.month &&
          a.createdAt.day == now.day;
    }).toList();
  }

  /// Returns the most recent activity with the given category, or null.
  Activity? getLastActivityByCategory(int categoryId) {
    return getAllActivities().where((a) => a.category.targetId == categoryId).firstOrNull;
  }

  bool deleteActivity(int id) => _activityBox.remove(id);

  int saveReward(Reward reward) => _rewardBox.put(reward);

  List<Reward> getAllRewards() => _rewardBox.getAll();

  Reward? getReward(int id) => _rewardBox.get(id);

  bool deleteReward(int id) => _rewardBox.remove(id);

  int saveTransaction(Transaction transaction) => _transactionBox.put(transaction);

  List<Transaction> getAllTransactions() =>
      _transactionBox.getAll()..sort((a, b) => b.date.compareTo(a.date));

  /// Total redeemed points in the current calendar month.
  double getMonthlyRedeemedPoints() {
    final now = DateTime.now();
    return getAllTransactions()
        .where((t) => t.isRedeem && t.date.year == now.year && t.date.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Total earned points today.
  double getTodayEarnedPoints() {
    final now = DateTime.now();
    return getAllTransactions()
        .where(
          (t) =>
              t.isEarn &&
              t.date.year == now.year &&
              t.date.month == now.month &&
              t.date.day == now.day,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// All-time total points earned (sum of all earn transactions).
  double getTotalEarnedPoints() {
    return getAllTransactions().where((t) => t.isEarn).fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Number of activities logged in the last 7 days.
  int getWeeklyActivitiesCount() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return getAllActivities().where((a) => a.createdAt.isAfter(cutoff)).length;
  }

  /// Points earned in the last 7 days.
  double getWeeklyEarnedPoints() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return getAllTransactions()
        .where((t) => t.isEarn && t.date.isAfter(cutoff))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Rewards redeemed in the last 7 days.
  int getWeeklyRedeemedCount() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return getAllTransactions().where((t) => t.isRedeem && t.date.isAfter(cutoff)).length;
  }

  /// Exports all data as a JSON string.
  String exportJson() {
    final user = getUser();
    final activities = getAllActivities();
    final rewards = getAllRewards();
    final transactions = getAllTransactions();

    final data = {
      'exportedAt': DateTime.now().toIso8601String(),
      'user': {
        'name': user.name,
        'pointBalance': user.pointBalance,
        'streak': user.streak,
        'monthlyBudget': user.monthlyBudget,
        'burnoutScore': user.burnoutScore,
        'adjustmentFactor': user.adjustmentFactor,
        'disciplineScore': user.disciplineScore,
        'income': user.income,
        'rewardPercentage': user.rewardPercentage,
        'onboardingDone': user.onboardingDone,
      },
      'activities': activities
          .map(
            (a) => {
              'title': a.title,
              'category': a.category.target?.name ?? 'Unknown',
              'durationMinutes': a.durationMinutes,
              'points': a.points,
              'createdAt': a.createdAt.toIso8601String(),
            },
          )
          .toList(),
      'rewards': rewards
          .map(
            (r) => {
              'name': r.name,
              'pointCost': r.pointCost,
              'progressPoints': r.progressPoints,
              'status': r.status,
            },
          )
          .toList(),
      'transactions': transactions
          .map(
            (t) => {
              'type': t.type,
              'amount': t.amount,
              'label': t.label,
              'date': t.date.toIso8601String(),
            },
          )
          .toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Clears all activity/reward/transaction data and resets point stats,
  /// but preserves the user's profile (name, onboarding, income, budget).
  void resetAllData() {
    final existingUser = getUser();
    _activityBox.removeAll();
    _rewardBox.removeAll();
    _transactionBox.removeAll();
    _userBox.removeAll();
    // Re-create the user keeping profile settings; reset point stats to zero.
    final resetUser = User(
      id: 0,
      name: existingUser.name,
      onboardingDone: existingUser.onboardingDone,
      income: existingUser.income,
      rewardPercentage: existingUser.rewardPercentage,
      monthlyBudget: existingUser.monthlyBudget,
    );
    _userBox.put(resetUser);
  }

  void close() => _store.close();

  // ─── Category ───────────────────────────────────────────────────────────────

  int saveCategory(Category category) => _categoryBox.put(category);
  List<Category> getAllCategories() => _categoryBox.getAll();
  Category? getCategory(int id) => _categoryBox.get(id);
  bool deleteCategory(int id) => _categoryBox.remove(id);

  // ─── ActivityPreset ─────────────────────────────────────────────────────────

  int saveActivityPreset(ActivityPreset preset) => _presetBox.put(preset);
  List<ActivityPreset> getAllActivityPresets() => _presetBox.getAll();
  ActivityPreset? getActivityPreset(int id) => _presetBox.get(id);
  bool deleteActivityPreset(int id) => _presetBox.remove(id);

  // ─── Quest ──────────────────────────────────────────────────────────────────

  int saveQuest(Quest quest) => _questBox.put(quest);
  List<Quest> getAllQuests() => _questBox.getAll();
  Quest? getQuest(int id) => _questBox.get(id);
  bool deleteQuest(int id) => _questBox.remove(id);

  // ─── Badge ──────────────────────────────────────────────────────────────────

  int saveBadge(Badge badge) => _badgeBox.put(badge);
  List<Badge> getAllBadges() => _badgeBox.getAll();
  Badge? getBadge(int id) => _badgeBox.get(id);
  bool deleteBadge(int id) => _badgeBox.remove(id);

  // ─── Habit Stack ────────────────────────────────────────────────────────┬

  int saveHabitStack(HabitStack stack) => _habitStackBox.put(stack);
  List<HabitStack> getAllHabitStacks() => _habitStackBox.getAll();
  HabitStack? getHabitStack(int id) => _habitStackBox.get(id);
  bool deleteHabitStack(int id) => _habitStackBox.remove(id);

  int saveStackItem(StackItem item) => _stackItemBox.put(item);
  StackItem? getStackItem(int id) => _stackItemBox.get(id);
  bool deleteStackItem(int id) => _stackItemBox.remove(id);
  // ─── Season & Event ─────────────────────────────────────────────────────────

  int saveSeason(Season season) => _seasonBox.put(season);
  List<Season> getAllSeasons() => _seasonBox.getAll();
  Season? getActiveSeason() {
    final now = DateTime.now();
    return _seasonBox.getAll().where((s) => s.isActive && s.startAt.isBefore(now) && s.endAt.isAfter(now)).firstOrNull;
  }

  int saveSeasonProgress(SeasonProgress progress) => _seasonProgressBox.put(progress);
  List<SeasonProgress> getAllSeasonProgress() => _seasonProgressBox.getAll();
  SeasonProgress? getSeasonProgressForUser(int userId, int seasonId) {
    return _seasonProgressBox.getAll().where((p) => p.user.targetId == userId && p.season.targetId == seasonId).firstOrNull;
  }

  int saveGameEvent(GameEvent event) => _eventBox.put(event);
  List<GameEvent> getAllGameEvents() => _eventBox.getAll();
  List<GameEvent> getActiveEvents() {
    final now = DateTime.now();
    return _eventBox.getAll().where((e) => e.isActive && e.startAt.isBefore(now) && e.endAt.isAfter(now)).toList();
  }
}
