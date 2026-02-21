import '../models/activity.dart';
import '../models/reward.dart';
import '../models/transaction.dart';
import '../models/user.dart';
import '../objectbox.g.dart';

/// The single layer that knows about ObjectBox.
/// All other services depend on this — never import objectbox directly elsewhere.
class StorageService {
  late final Store _store;

  Future<void> init() async {
    _store = await openStore();
    _seedUserIfEmpty();
  }

  Store get store => _store;

  // ─── Boxes ──────────────────────────────────────────────────────────────────

  Box<User> get _userBox => _store.box<User>();
  Box<Activity> get _activityBox => _store.box<Activity>();
  Box<Reward> get _rewardBox => _store.box<Reward>();
  Box<Transaction> get _transactionBox => _store.box<Transaction>();

  // ─── User ───────────────────────────────────────────────────────────────────

  /// Returns the single app user (id=1), creating a default one if absent.
  User getUser() {
    final user = _userBox.get(1);
    return user ?? _createDefaultUser();
  }

  int saveUser(User user) => _userBox.put(user);

  User _createDefaultUser() {
    final user = User(id: 1);
    _userBox.put(user);
    return user;
  }

  void _seedUserIfEmpty() {
    if (_userBox.get(1) == null) _createDefaultUser();
  }

  // ─── Activity ───────────────────────────────────────────────────────────────

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
  Activity? getLastActivityByCategory(String category) {
    return getAllActivities().where((a) => a.category == category).firstOrNull;
  }

  bool deleteActivity(int id) => _activityBox.remove(id);

  // ─── Reward ─────────────────────────────────────────────────────────────────

  int saveReward(Reward reward) => _rewardBox.put(reward);

  List<Reward> getAllRewards() => _rewardBox.getAll();

  Reward? getReward(int id) => _rewardBox.get(id);

  bool deleteReward(int id) => _rewardBox.remove(id);

  // ─── Transaction ────────────────────────────────────────────────────────────

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

  void close() => _store.close();
}
