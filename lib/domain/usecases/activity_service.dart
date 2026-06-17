import 'package:earnjoy/core/constants.dart';
import 'package:earnjoy/data/models/activity.dart';
import 'package:earnjoy/data/datasources/storage_service.dart';

class ActivityService {
  final StorageService _storage;

  ActivityService(this._storage);

  /// Adds an activity record. Does NOT mutate user balance
  /// Provider's responsibility after calling [PointEngine.calculatePoints].
  Activity addActivity({
    required String title,
    required int categoryId,
    required int durationMinutes,
    required double points,
  }) {
    final activity = Activity(title: title, durationMinutes: durationMinutes, points: points);
    activity.category.targetId = categoryId;
    final id = _storage.saveActivity(activity);
    return activity.copyWith(id: id);
  }

  /// Returns activities logged today, newest first.
  List<Activity> getTodayActivities() => _storage.getTodayActivities();

  /// Returns all activities, newest first.
  List<Activity> getAllActivities() => _storage.getAllActivities();

  /// Whether the cooldown for [categoryId] is still active.
  /// Rule: must wait [cooldownMinutes] minutes between same-category logs.
  bool isCooldownActive(int categoryId) {
    final last = _storage.getLastActivityByCategory(categoryId);
    if (last == null) return false;
    final elapsed = DateTime.now().difference(last.createdAt);
    return elapsed.inMinutes < cooldownMinutes;
  }

  /// Remaining cooldown in minutes for a given category (0 if inactive).
  int cooldownRemainingMinutes(int categoryId) {
    final last = _storage.getLastActivityByCategory(categoryId);
    if (last == null) return 0;
    final elapsed = DateTime.now().difference(last.createdAt).inMinutes;
    final remaining = cooldownMinutes - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  /// How many times [categoryId] was logged today (used for diminishing returns).
  int categoryCountToday(int categoryId) {
    return getTodayActivities().where((a) => a.category.targetId == categoryId).length;
  }
}
