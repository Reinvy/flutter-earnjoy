import 'package:flutter/material.dart';

import 'package:earnjoy/data/models/activity.dart';
import 'package:earnjoy/data/models/user.dart';
import 'package:earnjoy/data/datasources/storage_service.dart';
import 'package:earnjoy/domain/usecases/notification_service.dart';
import 'user_provider.dart';

class NotificationProvider extends ChangeNotifier {
  final StorageService _storage;
  final SmartNotificationService _service;
  UserProvider? _userProvider;

  NotificationProvider(this._storage, this._service);

  void setUserProvider(UserProvider userProvider) {
    _userProvider = userProvider;
  }

  // ─── Exposed state ───────────────────────────────────────────────────────

  User get _user => _userProvider?.user ?? _storage.getUser();

  bool get notificationsEnabled => _user.notificationsEnabled;
  int get quietHoursStart => _user.quietHoursStart;
  int get quietHoursEnd => _user.quietHoursEnd;
  int get preferredReminderHour => _user.preferredReminderHour;

  /// Returns the best reminder TimeOfDay based on recent activity patterns.
  TimeOfDay bestReminderTime(List<Activity> recentActivities) {
    return _service.bestReminderTimeOfDay(_user, recentActivities);
  }

  // ─── Actions ─────────────────────────────────────────────────────────────

  /// Toggles notification on/off. Requests permission on first enable.
  Future<bool> toggleNotifications() async {
    final current = notificationsEnabled;
    if (!current) {
      // Enabling — request permission first
      final granted = await _service.requestPermission();
      if (!granted) return false;
    }

    final updated = _user.copyWith(notificationsEnabled: !current);
    _storage.saveUser(updated);
    _userProvider?.loadUser();

    if (!current) {
      // Was off, now on — schedule initial notifications
      await _scheduleAll(updated);
    } else {
      // Was on, now off — cancel all
      await _service.cancelAll();
    }
    notifyListeners();
    return true;
  }

  /// Updates quiet hours and reschedules all with the new windows.
  Future<void> setQuietHours({
    required int startHour,
    required int endHour,
  }) async {
    final updated = _user.copyWith(
      quietHoursStart: startHour,
      quietHoursEnd: endHour,
    );
    _storage.saveUser(updated);
    _userProvider?.loadUser();
    await _scheduleAll(updated);
    notifyListeners();
  }

  /// Saves a manual preferred reminder hour (-1 = auto).
  Future<void> setPreferredReminderHour(int hour) async {
    final updated = _user.copyWith(preferredReminderHour: hour);
    _storage.saveUser(updated);
    _userProvider?.loadUser();
    await _scheduleAll(updated);
    notifyListeners();
  }

  /// Re-schedules all notifications. Called after activity log or app launch.
  Future<void> rescheduleAll() async {
    final user = _user;
    if (!user.notificationsEnabled) return;

    final activities = _storage.getAllActivities();
    final quests = _storage.getAllQuests().where((q) => !q.isCompleted).toList();
    final rewards = _storage.getAllRewards();

    await _service.rescheduleAll(
      user: user,
      recentActivities: activities,
      quests: quests,
      rewards: rewards,
    );
  }

  /// Initialize the notification service and schedule on cold start.
  Future<void> initAndSchedule() async {
    await _service.initialize();
    final user = _user;
    if (user.notificationsEnabled) {
      await rescheduleAll();
    }
  }

  // ─── Private ────────────────────────────────────────────────────────────

  Future<void> _scheduleAll(User user) async {
    if (!user.notificationsEnabled) return;
    final activities = _storage.getAllActivities();
    final quests = _storage.getAllQuests().where((q) => !q.isCompleted).toList();
    final rewards = _storage.getAllRewards();

    await _service.rescheduleAll(
      user: user,
      recentActivities: activities,
      quests: quests,
      rewards: rewards,
    );
  }
}
