import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:earnjoy/data/datasources/storage_service.dart';
import 'package:earnjoy/data/models/accountability_partner.dart';
import 'package:earnjoy/data/models/duel.dart';
import 'package:earnjoy/data/models/group_challenge.dart';
import 'package:earnjoy/presentation/providers/badge_provider.dart';
import 'package:earnjoy/presentation/providers/user_provider.dart';

class SocialProvider extends ChangeNotifier {
  final StorageService _storage;
  UserProvider? _userProvider;
  BadgeProvider? _badgeProvider;

  List<AccountabilityPartner> _partners = [];
  Duel? _activeDuel;
  GroupChallenge? _activeGroupChallenge;
  bool _isLoading = false;

  SocialProvider(this._storage) {
    _load();
  }

  // ─── Getters ─────────────────────────────────────────────────────────────────

  List<AccountabilityPartner> get partners => _partners;
  Duel? get activeDuel => _activeDuel;
  GroupChallenge? get activeGroupChallenge => _activeGroupChallenge;
  bool get isLoading => _isLoading;

  // ─── Dependency Injection ────────────────────────────────────────────────────

  void setUserProvider(UserProvider userProvider) {
    _userProvider = userProvider;
    notifyListeners();
  }

  void setBadgeProvider(BadgeProvider badgeProvider) {
    _badgeProvider = badgeProvider;
  }

  // ─── Internal Load ───────────────────────────────────────────────────────────

  void _load() {
    _partners = _storage.getAllPartners();
    _activeDuel = _storage.getActiveDuel();
    _activeGroupChallenge = _storage.getActiveGroupChallenge();
    // Auto-check expired duels and group challenges
    _checkExpiredDuel();
    _checkExpiredGroupChallenge();
    notifyListeners();
  }

  // ─── Social Enable / Disable ────────────────────────────────────────────────

  /// Enables social mode for the user: generates an invite code if not yet set.
  void enableSocial() {
    final user = _userProvider?.user;
    if (user == null) return;
    final code = user.inviteCode.isEmpty ? _storage.generateInviteCode() : user.inviteCode;
    _storage.saveUser(user.copyWith(socialEnabled: true, inviteCode: code));
    _userProvider?.loadUser();
    notifyListeners();
  }

  /// Disables social mode. Partners and duels remain stored locally.
  void disableSocial() {
    final user = _userProvider?.user;
    if (user == null) return;
    _storage.saveUser(user.copyWith(socialEnabled: false));
    _userProvider?.loadUser();
    notifyListeners();
  }

  // ─── Partners ────────────────────────────────────────────────────────────────

  /// Adds a new accountability partner locally (offline mock).
  /// [inviteCode] is stored for future backend pairing.
  /// [mockWeeklyPoints] and [mockStreakDays] are passed by the UI (simulated).
  void addPartner({
    required String name,
    required String inviteCode,
    double mockWeeklyPoints = 0,
    int mockStreakDays = 0,
  }) {
    if (name.trim().isEmpty) return;
    // Prevent duplicates by invite code
    if (_partners.any((p) => p.inviteCode == inviteCode.trim())) return;

    final partner = AccountabilityPartner(
      name: name.trim(),
      inviteCode: inviteCode.trim().toUpperCase(),
      weeklyPoints: mockWeeklyPoints,
      streakDays: mockStreakDays,
    );
    _storage.savePartner(partner);
    _partners = _storage.getAllPartners();
    notifyListeners();
  }

  void removePartner(int id) {
    _storage.deletePartner(id);
    _partners = _storage.getAllPartners();
    notifyListeners();
  }

  // ─── Duel ────────────────────────────────────────────────────────────────────

  /// Creates a new 7-day duel against a partner.
  bool createDuel({required int partnerId, required String partnerName}) {
    if (_activeDuel != null) return false; // only one duel at a time
    final duel = Duel(
      partnerId: partnerId,
      partnerName: partnerName,
      startAt: DateTime.now(),
      endAt: DateTime.now().add(const Duration(days: 7)),
    );
    _storage.saveDuel(duel);
    _activeDuel = _storage.getActiveDuel();
    notifyListeners();
    return true;
  }

  /// Syncs current user's weekly points earned into the active duel.
  void syncDuelProgress() {
    if (_activeDuel == null) return;
    final weeklyPoints = _storage.getWeeklyEarnedPoints();
    final updated = _activeDuel!.copyWith(myPoints: weeklyPoints);
    _storage.saveDuel(updated);
    _activeDuel = updated;
    notifyListeners();
  }

  /// Manually resolves the active duel (called when expired or user taps Resolve).
  /// Compares myPoints vs partnerPoints and sets the status, awarding badge if won.
  void resolveDuel() {
    if (_activeDuel == null) return;
    final duel = _activeDuel!;
    String newStatus;
    if (duel.myPoints > duel.partnerPoints) {
      newStatus = DuelStatus.userWon;
      // Award Duel Champion badge
      _badgeProvider?.tryUnlockBadge('duel_champion');
    } else if (duel.myPoints < duel.partnerPoints) {
      newStatus = DuelStatus.partnerWon;
    } else {
      newStatus = DuelStatus.draw;
    }
    final resolved = duel.copyWith(status: newStatus);
    _storage.saveDuel(resolved);
    _activeDuel = null;
    notifyListeners();
  }

  void _checkExpiredDuel() {
    if (_activeDuel != null && _activeDuel!.isExpired) {
      resolveDuel();
    }
  }

  // ─── Group Challenge ──────────────────────────────────────────────────────────

  /// Creates a new group challenge.
  bool createGroupChallenge({
    required String name,
    required String description,
    required double targetPoints,
    required int durationDays,
    required List<String> memberNames,
  }) {
    if (_activeGroupChallenge != null) return false; // only one active at a time
    final challenge = GroupChallenge(
      name: name.trim(),
      description: description.trim(),
      targetPoints: targetPoints,
      membersJson: jsonEncode(memberNames),
      startAt: DateTime.now(),
      endAt: DateTime.now().add(Duration(days: durationDays)),
    );
    _storage.saveGroupChallenge(challenge);
    _activeGroupChallenge = _storage.getActiveGroupChallenge();
    notifyListeners();
    return true;
  }

  /// Syncs user's earned points from the challenge start date into group challenge progress.
  void syncGroupChallengeProgress() {
    if (_activeGroupChallenge == null) return;
    final challenge = _activeGroupChallenge!;
    // Calculate points earned since challenge started
    final allTransactions = _storage.getAllTransactions();
    final earnedSinceStart = allTransactions
        .where((t) => t.isEarn && t.date.isAfter(challenge.startAt))
        .fold(0.0, (sum, t) => sum + t.amount);

    final updated = challenge.copyWith(currentPoints: earnedSinceStart);
    // Auto-complete if target reached
    if (earnedSinceStart >= challenge.targetPoints) {
      final completed = updated.copyWith(status: GroupChallengeStatus.completed);
      _storage.saveGroupChallenge(completed);
      _activeGroupChallenge = completed;
    } else {
      _storage.saveGroupChallenge(updated);
      _activeGroupChallenge = updated;
    }
    notifyListeners();
  }

  void _checkExpiredGroupChallenge() {
    final c = _activeGroupChallenge;
    if (c != null && c.isActive && DateTime.now().isAfter(c.endAt)) {
      final status = c.currentPoints >= c.targetPoints
          ? GroupChallengeStatus.completed
          : GroupChallengeStatus.failed;
      final resolved = c.copyWith(status: status);
      _storage.saveGroupChallenge(resolved);
      _activeGroupChallenge = resolved;
    }
  }

  void dismissGroupChallenge() {
    _activeGroupChallenge = null;
    notifyListeners();
  }

  void dismissDuel() {
    _activeDuel = null;
    notifyListeners();
  }

  List<String> getMembersFromChallenge(GroupChallenge challenge) {
    try {
      final list = jsonDecode(challenge.membersJson) as List<dynamic>;
      return list.cast<String>();
    } catch (_) {
      return [];
    }
  }
}
