import 'package:flutter/foundation.dart' hide Category;

import 'package:earnjoy/data/datasources/storage_service.dart';
import 'package:earnjoy/domain/usecases/burnout_service.dart';
import 'package:earnjoy/presentation/providers/activity_provider.dart';
import 'package:earnjoy/presentation/providers/user_provider.dart';

class WellbeingProvider extends ChangeNotifier {
  final StorageService _storage;
  final BurnoutService _burnoutService;
  UserProvider? _userProvider;

  double _burnoutScore = 0;
  BurnoutStatus _status = BurnoutStatus.healthy;
  String _balanceInsight = '';

  WellbeingProvider(this._storage)
      : _burnoutService = const BurnoutService();

  // ─── Getters ──────────────────────────────────────────────────────────────

  double get burnoutScore => _burnoutScore;
  BurnoutStatus get status => _status;
  String get balanceInsight => _balanceInsight;

  /// True if the user has NOT declared a rest day in the last 7 days.
  bool get canDeclareRestDay {
    final user = _storage.getUser();
    final last = user.lastRestDayDate;
    if (last.year < 2001) return true;
    return DateTime.now().difference(last).inDays >= 7;
  }

  int get restDayCount => _storage.getUser().restDayCount;

  // ─── Setters / Injection ──────────────────────────────────────────────────

  void setUserProvider(UserProvider userProvider) {
    _userProvider = userProvider;
    refresh();
  }

  void setActivityProvider(ActivityProvider activityProvider) {
    refresh();
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  /// Recomputes burnout score and balance insight from last 7 days of data.
  void refresh() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final recentActivities = _storage
        .getAllActivities()
        .where((a) => a.createdAt.isAfter(cutoff))
        .toList();

    _burnoutScore = _burnoutService.computeBurnoutScore(recentActivities);
    _status = _burnoutService.getStatus(_burnoutScore);

    final distribution = _storage.getCategoryDistribution('week');
    _balanceInsight = _burnoutService.getBalanceInsight(distribution);

    notifyListeners();
  }

  /// Declares today as a rest day:
  /// - Adds +10 bonus points without breaking the streak
  /// - Records the rest day date and increments counter
  Future<void> declareRestDay() async {
    if (!canDeclareRestDay) return;

    final user = _storage.getUser();
    final now = DateTime.now();

    // Preserve streak by updating lastActivityDate to today
    final updatedUser = user.copyWith(
      pointBalance: user.pointBalance + 10,
      xp: user.xp + 10,
      lastActivityDate: now,
      restDayCount: user.restDayCount + 1,
      lastRestDayDate: now,
    );
    _storage.saveUser(updatedUser);

    // Notify UserProvider to reload
    _userProvider?.loadUser();

    refresh();
  }
}
