import 'package:flutter/foundation.dart';

import 'package:earnjoy/data/models/reward.dart';
import 'package:earnjoy/domain/usecases/reward_service.dart';
import 'package:earnjoy/data/datasources/storage_service.dart';
import 'package:earnjoy/presentation/providers/badge_provider.dart';

class RewardProvider extends ChangeNotifier {
  final StorageService _storage;
  late final RewardService _rewardService;
  BadgeProvider? _badgeProvider;

  List<Reward> _rewards = [];

  RewardProvider(this._storage) {
    _rewardService = RewardService(_storage);
    loadRewards();
  }

  void setBadgeProvider(BadgeProvider badgeProvider) {
    _badgeProvider = badgeProvider;
  }

  List<Reward> get rewards => List.unmodifiable(_rewards);

  void loadRewards() {
    _rewards = _rewardService.getRewards();
    notifyListeners();
  }

  /// Alias for [loadRewards] - called externally after activity points are
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
    // Get cost before it's potentially modified/deleted by redeem
    final reward = _rewards.where((r) => r.id == rewardId).firstOrNull;
    final cost = reward?.pointCost ?? 0.0;

    final success = _rewardService.redeemReward(rewardId);
    if (success) {
      _rewards = _rewardService.getRewards();
      _badgeProvider?.evaluateRedeem(cost);
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
