import 'package:earnjoy/data/models/reward.dart';
import 'package:earnjoy/data/models/transaction.dart';
import 'package:earnjoy/data/models/user.dart';
import 'package:earnjoy/data/datasources/storage_service.dart';

class RewardService {
  final StorageService _storage;

  RewardService(this._storage);

 
  Reward addReward({required String name, required double pointCost}) {
    final reward = Reward(name: name, pointCost: pointCost);
    final id = _storage.saveReward(reward);
    return reward.copyWith(id: id);
  }

  List<Reward> getRewards() => _storage.getAllRewards();

  bool deleteReward(int id) => _storage.deleteReward(id);

  /// Attempts to redeem [rewardId].
  /// Returns `true` on success, `false` if already redeemed, balance is
  /// insufficient, or monthly budget is exceeded.
  bool redeemReward(int rewardId) {
    final reward = _storage.getReward(rewardId);
    if (reward == null) return false;
    if (reward.isRedeemed) return false;

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

  
  bool isMonthlyBudgetExceeded(User user) {
    // monthlyBudget == 0 means unlimited
    if (user.monthlyBudget <= 0) return false;
    final redeemed = _storage.getMonthlyRedeemedPoints();
    return redeemed >= user.monthlyBudget;
  }

  double monthlyBudgetUsed() => _storage.getMonthlyRedeemedPoints();
}
