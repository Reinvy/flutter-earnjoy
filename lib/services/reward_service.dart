import '../models/reward.dart';
import '../models/transaction.dart';
import '../models/user.dart';
import 'storage_service.dart';

class RewardService {
  final StorageService _storage;

  RewardService(this._storage);

  // ─── Reward CRUD ────────────────────────────────────────────────────────────

  Reward addReward({required String name, required double pointCost}) {
    final reward = Reward(name: name, pointCost: pointCost);
    final id = _storage.saveReward(reward);
    return reward.copyWith(id: id);
  }

  List<Reward> getRewards() => _storage.getAllRewards();

  bool deleteReward(int id) => _storage.deleteReward(id);

  // ─── Progress ───────────────────────────────────────────────────────────────

  /// Distribute newly earned [points] across all non-redeemed rewards
  /// proportionally (each reward gets the same absolute amount, capped at its
  /// own pointCost). Call this after every activity log.
  void distributePoints(double points) {
    final rewards = getRewards().where((r) => !r.isRedeemed).toList();
    if (rewards.isEmpty) return;

    for (final reward in rewards) {
      final newProgress = (reward.progressPoints + points).clamp(0.0, reward.pointCost);
      final newStatus = newProgress >= reward.pointCost
          ? RewardStatus.unlocked
          : RewardStatus.locked;
      _storage.saveReward(reward.copyWith(progressPoints: newProgress, status: newStatus));
    }
  }

  // ─── Redeem ─────────────────────────────────────────────────────────────────

  /// Attempts to redeem [rewardId].
  /// Returns `true` on success, `false` if balance is insufficient or budget
  /// exceeded.
  bool redeemReward(int rewardId) {
    final reward = _storage.getReward(rewardId);
    if (reward == null) return false;
    if (!reward.isUnlocked) return false;

    final user = _storage.getUser();
    if (user.pointBalance < reward.pointCost) return false;
    if (isMonthlyBudgetExceeded(user)) return false;

    // Deduct points
    _storage.saveUser(user.copyWith(pointBalance: user.pointBalance - reward.pointCost));

    // Mark redeemed
    _storage.saveReward(reward.copyWith(status: RewardStatus.redeemed));

    // Record transaction
    _storage.saveTransaction(
      Transaction(type: TransactionType.redeem, amount: reward.pointCost, label: reward.name),
    );

    return true;
  }

  // ─── Budget ─────────────────────────────────────────────────────────────────

  bool isMonthlyBudgetExceeded(User user) {
    final redeemed = _storage.getMonthlyRedeemedPoints();
    return redeemed >= user.monthlyBudget;
  }

  double monthlyBudgetUsed() => _storage.getMonthlyRedeemedPoints();
}
