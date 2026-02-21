import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/storage_service.dart';

class UserProvider extends ChangeNotifier {
  final StorageService _storage;
  late User _user;

  UserProvider(this._storage) {
    loadUser();
  }

  User get user => _user;

  /// Whether the burnout threshold has been hit (score >= 3 consecutive misses).
  bool get isBurnedOut => _user.burnoutScore >= 3;

  void loadUser() {
    _user = _storage.getUser();
    _checkAndResetStreak();
    notifyListeners();
  }

  /// Auto-resets streak and increments burnoutScore if the user missed yesterday.
  /// Called silently on every app launch via [loadUser].
  void _checkAndResetStreak() {
    // New/default users (lastActivityDate == year 2000) are skipped
    if (_user.lastActivityDate.year < 2001) return;
    if (_user.streak == 0) return;

    final now = DateTime.now();
    final last = _user.lastActivityDate;
    final isToday = last.year == now.year && last.month == now.month && last.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final wasYesterday =
        last.year == yesterday.year && last.month == yesterday.month && last.day == yesterday.day;

    if (!isToday && !wasYesterday) {
      // Missed at least one day — streak broken
      final newBurnout = (_user.burnoutScore + 1).clamp(0.0, 10.0);
      _user = _user.copyWith(streak: 0, burnoutScore: newBurnout);
      _storage.saveUser(_user);
    }
  }

  void updateBalance(double delta) {
    _user = _user.copyWith(pointBalance: _user.pointBalance + delta);
    _storage.saveUser(_user);
    notifyListeners();
  }

  /// Updates balance AND recalculates streak atomically after every activity log.
  void updateAfterActivity(double pointsDelta) {
    final now = DateTime.now();
    final last = _user.lastActivityDate;

    final isToday = last.year == now.year && last.month == now.month && last.day == now.day;

    final yesterday = now.subtract(const Duration(days: 1));
    final wasYesterday =
        last.year == yesterday.year && last.month == yesterday.month && last.day == yesterday.day;

    int newStreak;
    if (isToday) {
      newStreak = _user.streak; // already incremented today
    } else if (wasYesterday) {
      newStreak = _user.streak + 1;
    } else {
      newStreak = 1; // streak broken — current activity starts a fresh streak
    }

    // Recover burnout when streak is being maintained
    double newBurnout = _user.burnoutScore;
    if (wasYesterday && newBurnout > 0) {
      newBurnout = (newBurnout - 1).clamp(0.0, 10.0);
    }

    _user = _user.copyWith(
      pointBalance: (_user.pointBalance + pointsDelta).clamp(0.0, double.infinity),
      streak: newStreak,
      lastActivityDate: now,
      burnoutScore: newBurnout,
    );
    _storage.saveUser(_user);
    notifyListeners();
  }

  /// Dismisses the burnout notice by resetting the score.
  void dismissBurnout() {
    if (_user.burnoutScore <= 0) return;
    _user = _user.copyWith(burnoutScore: 0);
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
