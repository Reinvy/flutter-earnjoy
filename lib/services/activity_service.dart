import '../core/constants.dart';
import '../models/activity.dart';
import 'storage_service.dart';

class ActivityService {
  final StorageService _storage;

  ActivityService(this._storage);

  /// Adds an activity record. Does NOT mutate user balance — that is the
  /// Provider's responsibility after calling [PointEngine.calculatePoints].
  Activity addActivity({
    required String title,
    required String category,
    required int durationMinutes,
    required double points,
  }) {
    final activity = Activity(
      title: title,
      category: category,
      durationMinutes: durationMinutes,
      points: points,
    );
    final id = _storage.saveActivity(activity);
    return activity.copyWith(id: id);
  }

  /// Returns activities logged today, newest first.
  List<Activity> getTodayActivities() => _storage.getTodayActivities();

  /// Returns all activities, newest first.
  List<Activity> getAllActivities() => _storage.getAllActivities();

  /// Whether the cooldown for [category] is still active.
  /// Rule: must wait [cooldownMinutes] minutes between same-category logs.
  bool isCooldownActive(String category) {
    final last = _storage.getLastActivityByCategory(category);
    if (last == null) return false;
    final elapsed = DateTime.now().difference(last.createdAt);
    return elapsed.inMinutes < cooldownMinutes;
  }

  /// Remaining cooldown in minutes for a given category (0 if inactive).
  int cooldownRemainingMinutes(String category) {
    final last = _storage.getLastActivityByCategory(category);
    if (last == null) return 0;
    final elapsed = DateTime.now().difference(last.createdAt).inMinutes;
    final remaining = cooldownMinutes - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  /// How many times [category] was logged today (used for diminishing returns).
  int categoryCountToday(String category) {
    return getTodayActivities().where((a) => a.category == category).length;
  }
}
