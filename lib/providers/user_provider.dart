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

  void loadUser() {
    _user = _storage.getUser();
    notifyListeners();
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

    _user = _user.copyWith(
      pointBalance: _user.pointBalance + pointsDelta,
      streak: newStreak,
      lastActivityDate: now,
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
