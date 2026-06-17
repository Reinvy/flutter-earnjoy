import 'package:earnjoy/data/models/reward.dart';
import 'package:earnjoy/data/models/transaction.dart';
import 'package:earnjoy/data/models/user.dart';
import 'package:earnjoy/data/datasources/storage_service.dart';

class RewardService {
  final StorageService _storage;

  RewardService(this._storage);

  Reward addReward({
    required String name,
    required double pointCost,
    String category = RewardCategory.food,
    String iconEmoji = '🎁',
    String recurrenceType = RecurrenceType.once,
    int? recurrenceIntervalDays,
    int? monthlyLimit,
    DateTime? scheduledFor,
  }) {
    final reward = Reward(
      name: name,
      pointCost: pointCost,
      category: category,
      iconEmoji: iconEmoji,
      recurrenceType: recurrenceType,
      recurrenceIntervalDays: recurrenceIntervalDays,
      monthlyLimit: monthlyLimit,
      scheduledFor: scheduledFor,
      isTemplate: false,
      isArchived: false,
    );
    final id = _storage.saveReward(reward);
    return reward.copyWith(id: id);
  }

  /// Add a reward from a template — copies category, emoji, pointCost, recurrence,
  /// but removes the isTemplate flag so it appears in the user's personal wishlist.
  Reward addRewardFromTemplate(Reward template) {
    final reward = Reward(
      name: template.name,
      pointCost: template.pointCost,
      category: template.category,
      iconEmoji: template.iconEmoji,
      recurrenceType: template.recurrenceType,
      recurrenceIntervalDays: template.recurrenceIntervalDays,
      monthlyLimit: template.monthlyLimit,
      isTemplate: false,
      isArchived: false,
    );
    final id = _storage.saveReward(reward);
    return reward.copyWith(id: id);
  }

  List<Reward> getRewards() => _storage.getAllActiveRewards();

  List<Reward> getArchivedRewards() => _storage.getArchivedRewards();

  List<Reward> getTemplateRewards() => _storage.getTemplateRewards();

  bool deleteReward(int id) => _storage.deleteReward(id);

  bool archiveReward(int id) {
    final reward = _storage.getReward(id);
    if (reward == null) return false;
    _storage.saveReward(reward.copyWith(isArchived: true));
    return true;
  }

  bool scheduleReward(int id, DateTime date) {
    final reward = _storage.getReward(id);
    if (reward == null) return false;
    _storage.saveReward(reward.copyWith(scheduledFor: date));
    return true;
  }

  /// Attempts to redeem [rewardId].
  /// Returns `true` on success, `false` if already redeemed, balance is
  /// insufficient, or monthly budget is exceeded.
  bool redeemReward(int rewardId) {
    final reward = _storage.getReward(rewardId);
    if (reward == null) return false;

    final user = _storage.getUser();
    if (user.pointBalance < reward.pointCost) return false;
    if (isMonthlyBudgetExceeded(user)) return false;

    // Handle different recurrence types
    if (reward.recurrenceType == RecurrenceType.once) {
      if (reward.isRedeemed) return false;
    } else if (reward.recurrenceType == RecurrenceType.recurring) {
      if (!reward.isRecurringReady) return false;
    } else if (reward.recurrenceType == RecurrenceType.limited) {
      // Check monthly redeem count for this specific reward
      final monthlyRedeemed = _storage.getMonthlyRedeemCountForReward(rewardId);
      final limit = reward.monthlyLimit ?? 1;
      if (monthlyRedeemed >= limit) return false;
    }

    // Deduct points
    _storage.saveUser(user.copyWith(pointBalance: user.pointBalance - reward.pointCost));

    // Record transaction
    _storage.saveTransaction(
      Transaction(type: TransactionType.redeem, amount: reward.pointCost, label: reward.name),
    );

    // Update reward state based on recurrence
    if (reward.recurrenceType == RecurrenceType.once) {
      _storage.saveReward(reward.copyWith(
        status: RewardStatus.redeemed,
        timesRedeemed: reward.timesRedeemed + 1,
        lastRedeemedAt: DateTime.now().toIso8601String(),
      ));
    } else {
      // Recurring and limited: keep it active but update cooldown/counter
      _storage.saveReward(reward.copyWith(
        timesRedeemed: reward.timesRedeemed + 1,
        lastRedeemedAt: DateTime.now().toIso8601String(),
        // For recurring: status stays locked so it's available again after cooldown
        status: RewardStatus.locked,
      ));
    }

    return true;
  }

  bool isMonthlyBudgetExceeded(User user) {
    // monthlyBudget == 0 means unlimited
    if (user.monthlyBudget <= 0) return false;
    final redeemed = _storage.getMonthlyRedeemedPoints();
    return redeemed >= user.monthlyBudget;
  }

  double monthlyBudgetUsed() => _storage.getMonthlyRedeemedPoints();
}
