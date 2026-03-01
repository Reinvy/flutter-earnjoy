import 'package:flutter/foundation.dart';

import 'package:earnjoy/data/models/user.dart';
import 'package:earnjoy/data/datasources/storage_service.dart';
import 'package:earnjoy/core/utils/level_system.dart';
import 'package:earnjoy/presentation/providers/season_provider.dart';
import 'package:earnjoy/domain/usecases/widget_sync_service.dart';

class UserProvider extends ChangeNotifier {
  final StorageService _storage;
  late User _user;

  UserProvider(this._storage) {
    loadUser();
  }

  User get user => _user;
  SeasonProvider? _seasonProvider;

  void setSeasonProvider(SeasonProvider seasonProvider) {
    _seasonProvider = seasonProvider;
    if (_user.id != 0) {
      _seasonProvider?.loadSeasonData(_user.id);
    }
  }

  /// Whether the burnout threshold has been hit (score >= 3 consecutive misses).
  bool get isBurnedOut => _user.burnoutScore >= 3;

  int get currentLevel => LevelSystem.currentLevel(_user.xp);
  String get currentTierName => LevelSystem.getTierName(currentLevel);
  double get xpProgress => LevelSystem.getProgress(_user.xp);
  double get xpForNextLevel => LevelSystem.xpForNextLevel(currentLevel);
  double get pointMultiplier => LevelSystem.getPointMultiplier(currentLevel);

  void loadUser() {
    _user = _storage.getUser();
    _checkAndResetStreak();
    _checkWeeklyAdjustment();
    notifyListeners();
  }

  /// Formula: 1.0 - (burnoutScore * 0.1) + (disciplineScore * 0.05)
  /// Clamped to [0.5, 1.5].
  ///
  ///   burnout=0,  discipline=0  -> 1.00 (neutral)
  ///   burnout=3,  discipline=0  -> 0.70 (mild reduction)
  ///   burnout=10, discipline=0  -> 0.50 (min cap)
  ///   burnout=0,  discipline=10 -> 1.50 (max cap)
  void _recalculateAdjustmentFactor() {
    final factor = (1.0 - _user.burnoutScore * 0.1 + _user.disciplineScore * 0.05).clamp(0.5, 1.5);
    _user = _user.copyWith(adjustmentFactor: factor);
  }

  /// Auto-resets streak and increments burnoutScore if the user missed yesterday.
  /// Called silently on every app launch via [loadUser].
  void _checkAndResetStreak() {
    if (_user.lastActivityDate.year < 2001) return;
    if (_user.streak == 0) return;

    final now = DateTime.now();
    final last = _user.lastActivityDate;
    final isToday = last.year == now.year && last.month == now.month && last.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final wasYesterday =
        last.year == yesterday.year && last.month == yesterday.month && last.day == yesterday.day;

    if (!isToday && !wasYesterday) {
      // Missed at least one day - streak broken
      final newBurnout = (_user.burnoutScore + 1).clamp(0.0, 10.0);
      final newDiscipline = (_user.disciplineScore - 0.5).clamp(0.0, 10.0);
      _user = _user.copyWith(streak: 0, burnoutScore: newBurnout, disciplineScore: newDiscipline);
      _recalculateAdjustmentFactor();
      _storage.saveUser(_user);
    }
  }

  /// Runs once per week on app launch. Counts distinct active days in the last
  /// 7 days and adjusts disciplineScore / burnoutScore accordingly.
  ///
  ///   >= 5 active days -> discipline +1   (great week)
  ///   3-4 active days -> discipline +0.5 (decent week)
  ///   <= 2 active days -> discipline -1, burnout +0.5 (weak week)
  void _checkWeeklyAdjustment() {
    final now = DateTime.now();
    final last = _user.lastWeeklyAdjustmentDate;
    if (now.difference(last).inDays < 7) return;

    // First-time: just stamp the date, no penalty
    if (last.year < 2001) {
      _user = _user.copyWith(lastWeeklyAdjustmentDate: now);
      _storage.saveUser(_user);
      return;
    }

    final cutoff = now.subtract(const Duration(days: 7));
    final activeDays = _storage
        .getAllTransactions()
        .where((t) => t.isEarn && t.date.isAfter(cutoff))
        .map((t) => '${t.date.year}-${t.date.month}-${t.date.day}')
        .toSet()
        .length;

    double newDiscipline = _user.disciplineScore;
    double newBurnout = _user.burnoutScore;

    if (activeDays >= 5) {
      newDiscipline = (newDiscipline + 1).clamp(0.0, 10.0);
    } else if (activeDays <= 2) {
      newDiscipline = (newDiscipline - 1).clamp(0.0, 10.0);
      newBurnout = (newBurnout + 0.5).clamp(0.0, 10.0);
    } else {
      newDiscipline = (newDiscipline + 0.5).clamp(0.0, 10.0);
    }

    _user = _user.copyWith(
      disciplineScore: newDiscipline,
      burnoutScore: newBurnout,
      lastWeeklyAdjustmentDate: now,
    );
    _recalculateAdjustmentFactor();
    _storage.saveUser(_user);
  }

 
  void updateBalance(double delta) {
    double newXp = _user.xp;
    if (delta > 0) {
      newXp += delta;
    }
    _user = _user.copyWith(pointBalance: _user.pointBalance + delta, xp: newXp);
    _storage.saveUser(_user);
    WidgetSyncService.updateWidget(_user);
    // Season XP tracking handled elsewhere or to be implemented
    notifyListeners();
  }

  /// Updates balance, streak, discipline, and recalculates adjustmentFactor
  /// atomically after every activity log.
  void updateAfterActivity(double pointsDelta) {
    final now = DateTime.now();
    final last = _user.lastActivityDate;

    final isToday = last.year == now.year && last.month == now.month && last.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final wasYesterday =
        last.year == yesterday.year && last.month == yesterday.month && last.day == yesterday.day;

    int newStreak;
    if (isToday) {
      newStreak = _user.streak;
    } else if (wasYesterday) {
      newStreak = _user.streak + 1;
    } else {
      newStreak = 1;
    }

    double newBurnout = _user.burnoutScore;
    double newDiscipline = _user.disciplineScore;

    if (wasYesterday) {
      // Continuing streak: recover burnout + small discipline boost
      if (newBurnout > 0) newBurnout = (newBurnout - 1).clamp(0.0, 10.0);
      newDiscipline = (newDiscipline + 0.1).clamp(0.0, 10.0);
    } else if (!isToday) {
      // Fresh start after a gap: small discipline penalty already applied by streak reset
      newDiscipline = (newDiscipline - 0.5).clamp(0.0, 10.0);
    }

    _user = _user.copyWith(
      pointBalance: (_user.pointBalance + pointsDelta).clamp(0.0, double.infinity),
      xp: _user.xp + pointsDelta,
      streak: newStreak,
      lastActivityDate: now,
      burnoutScore: newBurnout,
      disciplineScore: newDiscipline,
    );
    _recalculateAdjustmentFactor();
    _storage.saveUser(_user);
    WidgetSyncService.updateWidget(_user);
    // Season XP tracking handled elsewhere or to be implemented
    notifyListeners();
  }

  /// Dismisses the burnout notice by resetting the score, then recalculates factor.
  void dismissBurnout() {
    if (_user.burnoutScore <= 0) return;
    _user = _user.copyWith(burnoutScore: 0);
    _recalculateAdjustmentFactor();
    _storage.saveUser(_user);
    notifyListeners();
  }

 
  /// Persists all onboarding choices and marks the flow as done.
  /// [monthlyBudget] is calculated upstream as income Ã— rewardPercentage.
  void completeOnboarding({
    required String name,
    required double income,
    required double rewardPercentage,
    required double monthlyBudget,
  }) {
    _user = _user.copyWith(
      name: name.trim().isEmpty ? 'User' : name.trim(),
      income: income.clamp(0.0, double.infinity),
      rewardPercentage: rewardPercentage.clamp(0.0, 1.0),
      monthlyBudget: monthlyBudget.clamp(0.0, double.infinity),
      onboardingDone: true,
    );
    _storage.saveUser(_user);
    notifyListeners();
  }

 
  void incrementStreak() {
    _user = _user.copyWith(streak: _user.streak + 1);
    _storage.saveUser(_user);
    notifyListeners();
  }

  void resetStreak() {
    _user = _user.copyWith(streak: 0);
    _storage.saveUser(_user);
    notifyListeners();
  }

  void updateName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _user = _user.copyWith(name: trimmed);
    _storage.saveUser(_user);
    notifyListeners();
  }

  void updateMonthlyBudget(double budget) {
    _user = _user.copyWith(monthlyBudget: budget.clamp(0.0, double.infinity));
    _storage.saveUser(_user);
    notifyListeners();
  }
}
