import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:earnjoy/data/datasources/storage_service.dart';
import 'package:earnjoy/data/models/activity.dart';
import 'package:earnjoy/data/models/badge.dart';
import 'package:earnjoy/data/models/user.dart';
import 'package:earnjoy/domain/usecases/badge_service.dart';

class BadgeProvider extends ChangeNotifier {
  final StorageService _storage;
  late final BadgeService _badgeService;

  List<Badge> _allBadges = [];
  List<Badge> get unlockedBadges => _allBadges.where((b) => b.isUnlocked).toList();
  List<Badge> get lockedBadges => _allBadges.where((b) => !b.isUnlocked).toList();

  BadgeProvider(this._storage) {
    _badgeService = BadgeService(_storage);
    _badgeService.ensureDefaultBadges();
    _loadBadges();
  }

  void _loadBadges() {
    _allBadges = _storage.getAllBadges();
    _allBadges.sort((a, b) => a.rarity.compareTo(b.rarity)); // Sort by rarity or other metric
    notifyListeners();
  }

  // Define an event stream or callback mechanism for the UI to listen for badge unlocks
  // Typically, we can just use a Function(Badge) callback, or expose a Stream.
  final _badgeUnlockController = StreamController<Badge>.broadcast();
  Stream<Badge> get onBadgeUnlocked => _badgeUnlockController.stream;

  void evaluateActivity(Activity activity) {
    final newlyUnlocked = _badgeService.evaluateActivity(activity);
    _handleUnlockedList(newlyUnlocked);
  }

  void evaluateStreak(User user) {
    final newlyUnlocked = _badgeService.evaluateStreak(user.streak);
    _handleUnlockedList(newlyUnlocked);
  }

  void evaluateRedeem(double cost) {
    // We pass cost for potential future volume badges, but logic handles it via total counts right now.
    final newlyUnlocked = _badgeService.evaluateRedeemAmount(cost.toInt());
    _handleUnlockedList(newlyUnlocked);
  }

  void _handleUnlockedList(List<Badge> newlyUnlocked) {
    if (newlyUnlocked.isNotEmpty) {
      _loadBadges(); // reload state
      for (var badge in newlyUnlocked) {
        _badgeUnlockController.add(badge);
      }
    }
  }

  @override
  void dispose() {
    _badgeUnlockController.close();
    super.dispose();
  }
}
