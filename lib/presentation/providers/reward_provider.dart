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
  List<Reward> _archivedRewards = [];
  List<Reward> _templateRewards = [];

  /// Currently selected category filter for the wishlist tab
  String? _wishlistCategoryFilter;

  /// Currently selected category filter for the shop/templates tab
  String? _shopCategoryFilter;

  RewardProvider(this._storage) {
    _rewardService = RewardService(_storage);
    loadRewards();
  }

  void setBadgeProvider(BadgeProvider badgeProvider) {
    _badgeProvider = badgeProvider;
  }

  // ─── Getters ───────────────────────────────────────────────────────────────

  List<Reward> get rewards => List.unmodifiable(_rewards);

  List<Reward> get archivedRewards => List.unmodifiable(_archivedRewards);

  List<Reward> get templateRewards => List.unmodifiable(_templateRewards);

  String? get wishlistCategoryFilter => _wishlistCategoryFilter;

  String? get shopCategoryFilter => _shopCategoryFilter;

  /// Active rewards filtered by [_wishlistCategoryFilter] if set
  List<Reward> get filteredRewards {
    if (_wishlistCategoryFilter == null) return rewards;
    return rewards.where((r) => r.category == _wishlistCategoryFilter).toList();
  }

  /// Templates filtered by [_shopCategoryFilter] if set
  List<Reward> get filteredTemplates {
    if (_shopCategoryFilter == null) return templateRewards;
    return templateRewards.where((r) => r.category == _shopCategoryFilter).toList();
  }

  /// IDs of templates that the user has already added to their wishlist
  Set<String> get addedTemplateNames =>
      _rewards.map((r) => r.name).toSet();

  // ─── Filters ───────────────────────────────────────────────────────────────

  void setWishlistCategoryFilter(String? category) {
    _wishlistCategoryFilter = category;
    notifyListeners();
  }

  void setShopCategoryFilter(String? category) {
    _shopCategoryFilter = category;
    notifyListeners();
  }

  // ─── Data Loading ──────────────────────────────────────────────────────────

  void loadRewards() {
    _rewards = _rewardService.getRewards();
    _archivedRewards = _rewardService.getArchivedRewards();
    _templateRewards = _rewardService.getTemplateRewards();
    notifyListeners();
  }

  /// Alias for [loadRewards] - called externally after activity points are
  /// distributed to keep the reward UI in sync.
  void refresh() => loadRewards();

  // ─── Mutations ─────────────────────────────────────────────────────────────

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
    final reward = _rewardService.addReward(
      name: name,
      pointCost: pointCost,
      category: category,
      iconEmoji: iconEmoji,
      recurrenceType: recurrenceType,
      recurrenceIntervalDays: recurrenceIntervalDays,
      monthlyLimit: monthlyLimit,
      scheduledFor: scheduledFor,
    );
    loadRewards();
    return reward;
  }

  /// Add a template to the user's personal wishlist
  Reward? addFromTemplate(Reward template) {
    final reward = _rewardService.addRewardFromTemplate(template);
    loadRewards();
    return reward;
  }

  /// Returns `true` on successful redeem; `false` if blocked.
  bool redeem(int rewardId) {
    final reward = _rewards.where((r) => r.id == rewardId).firstOrNull;
    final cost = reward?.pointCost ?? 0.0;

    final success = _rewardService.redeemReward(rewardId);
    if (success) {
      _badgeProvider?.evaluateRedeem(cost);
      loadRewards();
    }
    return success;
  }

  bool deleteReward(int id) {
    final success = _rewardService.deleteReward(id);
    if (success) loadRewards();
    return success;
  }

  bool archiveReward(int id) {
    final success = _rewardService.archiveReward(id);
    if (success) loadRewards();
    return success;
  }

  bool scheduleReward(int id, DateTime date) {
    final success = _rewardService.scheduleReward(id, date);
    if (success) loadRewards();
    return success;
  }
}
