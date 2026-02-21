import 'package:flutter/foundation.dart';

import '../models/reward.dart';
import '../services/reward_service.dart';
import '../services/storage_service.dart';

class RewardProvider extends ChangeNotifier {
  final StorageService _storage;
  late final RewardService _rewardService;

  List<Reward> _rewards = [];

  RewardProvider(this._storage) {
    _rewardService = RewardService(_storage);
    loadRewards();
  }

  List<Reward> get rewards => List.unmodifiable(_rewards);

  void loadRewards() {
    _rewards = _rewardService.getRewards();
    notifyListeners();
  }

  /// Alias for [loadRewards] — called externally after activity points are
  /// distributed to keep the reward UI in sync.
  void refresh() => loadRewards();

  Reward addReward({required String name, required double pointCost}) {
    final reward = _rewardService.addReward(name: name, pointCost: pointCost);
    _rewards = _rewardService.getRewards();
    notifyListeners();
    return reward;
  }

  /// Returns `true` on successful redeem; `false` if blocked.
  bool redeem(int rewardId) {
    final success = _rewardService.redeemReward(rewardId);
    if (success) {
      _rewards = _rewardService.getRewards();
      notifyListeners();
    }
    return success;
  }

  bool deleteReward(int id) {
    final success = _rewardService.deleteReward(id);
    if (success) {
      _rewards = _rewardService.getRewards();
      notifyListeners();
    }
    return success;
  }
}
