import 'package:earnjoy/data/datasources/storage_service.dart';
import 'package:earnjoy/data/datasources/supabase_service.dart';
import 'package:earnjoy/data/models/activity.dart';
import 'package:earnjoy/data/models/reward.dart';

/// Offline-first sync orchestrator.
///
/// Strategy:
///   1. All writes go to ObjectBox first (instant, always works offline).
///   2. Call [fullSync] to: push local → then pull & merge remote.
///   3. Conflict resolution: **last-write-wins** based on `updatedAt`.
class SyncService {
  final SupabaseService _supabase;

  SyncService(this._supabase);

  bool _isSyncing = false;
  DateTime? _lastSyncAt;
  String? _error;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncAt => _lastSyncAt;
  String? get error => _error;

  // ─── Full Sync ────────────────────────────────────────────────────────────

  /// Push local data to cloud, then pull & merge remote data.
  /// Returns true if sync completed successfully.
  Future<bool> fullSync(StorageService storage) async {
    if (!_supabase.isSignedIn) return false;
    if (_isSyncing) return false;

    _isSyncing = true;
    _error = null;

    try {
      await _pushLocalData(storage);
      await _pullAndMerge(storage);
      _lastSyncAt = DateTime.now();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  // ─── Push ─────────────────────────────────────────────────────────────────

  Future<void> _pushLocalData(StorageService storage) async {
    final user = storage.getUser();
    final activities = storage.getAllActivities();
    final rewards = storage.getAllRewards();
    final quests = storage.getAllQuests();
    final badges = storage.getAllBadges();

    await _supabase.upsertUser(user);
    await _supabase.upsertActivities(activities);
    await _supabase.upsertRewards(rewards);
    await _supabase.upsertQuests(quests);
    await _supabase.upsertBadges(badges);
  }

  // ─── Pull & Merge ─────────────────────────────────────────────────────────

  Future<void> _pullAndMerge(StorageService storage) async {
    await _mergeUser(storage);
    await _mergeActivities(storage);
    await _mergeRewards(storage);
    await _mergeQuests(storage);
    await _mergeBadges(storage);
  }

  Future<void> _mergeUser(StorageService storage) async {
    final remote = await _supabase.fetchUser();
    if (remote == null) return;

    final local = storage.getUser();
    final remoteUpdatedAt = DateTime.tryParse(remote['updated_at'] ?? '') ?? DateTime(2000);

    if (remoteUpdatedAt.isAfter(local.updatedAt)) {
      // Remote is newer — update local (preserve local-only fields like notifications)
      final updated = local.copyWith(
        name: remote['name'] as String? ?? local.name,
        pointBalance: (remote['point_balance'] as num?)?.toDouble() ?? local.pointBalance,
        streak: remote['streak'] as int? ?? local.streak,
        xp: (remote['xp'] as num?)?.toDouble() ?? local.xp,
        cloudId: remote['id'] as String?,
        updatedAt: remoteUpdatedAt,
      );
      storage.saveUser(updated);
    } else {
      // Local is newer — just update cloudId if not set
      if (local.cloudId == null && remote['id'] != null) {
        storage.saveUser(local.copyWith(cloudId: remote['id'] as String));
      }
    }
  }

  Future<void> _mergeActivities(StorageService storage) async {
    final remoteList = await _supabase.fetchActivities();
    final localList = storage.getAllActivities();
    final localByCloudId = {for (var a in localList.where((a) => a.cloudId != null)) a.cloudId!: a};

    for (final remote in remoteList) {
      final remoteId = remote['id'] as String?;
      final remoteUpdatedAt = DateTime.tryParse(remote['updated_at'] ?? '') ?? DateTime(2000);

      final local = remoteId != null ? localByCloudId[remoteId] : null;

      if (local == null) {
        // New activity from another device — create locally
        final category = storage.getAllCategories().where(
          (c) => c.name == (remote['category_name'] as String? ?? 'Other')
        ).firstOrNull;
        final newActivity = Activity(
          title: remote['title'] as String? ?? '',
          durationMinutes: remote['duration_minutes'] as int? ?? 0,
          points: (remote['points'] as num?)?.toDouble() ?? 0,
          createdAt: DateTime.tryParse(remote['created_at'] ?? '') ?? DateTime.now(),
          cloudId: remoteId,
          updatedAt: remoteUpdatedAt,
        );
        if (category != null) newActivity.category.target = category;
        storage.saveActivity(newActivity);
      } else if (remoteUpdatedAt.isAfter(local.updatedAt)) {
        // Remote is newer — update local
        final updated = local.copyWith(
          title: remote['title'] as String? ?? local.title,
          durationMinutes: remote['duration_minutes'] as int? ?? local.durationMinutes,
          points: (remote['points'] as num?)?.toDouble() ?? local.points,
          cloudId: remoteId,
          updatedAt: remoteUpdatedAt,
        );
        storage.saveActivity(updated);
      }
    }
  }

  Future<void> _mergeRewards(StorageService storage) async {
    final remoteList = await _supabase.fetchRewards();
    final localList = storage.getAllActiveRewards();
    final localByCloudId = {for (var r in localList.where((r) => r.cloudId != null)) r.cloudId!: r};

    for (final remote in remoteList) {
      final remoteId = remote['id'] as String?;
      final remoteUpdatedAt = DateTime.tryParse(remote['updated_at'] ?? '') ?? DateTime(2000);
      final local = remoteId != null ? localByCloudId[remoteId] : null;

      if (local == null) {
        final newReward = Reward(
          name: remote['name'] as String? ?? '',
          pointCost: (remote['point_cost'] as num?)?.toDouble() ?? 0,
          status: remote['status'] as String? ?? 'locked',
          category: remote['category'] as String? ?? 'food',
          iconEmoji: remote['icon_emoji'] as String? ?? '🎁',
          recurrenceType: remote['recurrence_type'] as String? ?? 'once',
          timesRedeemed: remote['times_redeemed'] as int? ?? 0,
          isArchived: remote['is_archived'] as bool? ?? false,
          cloudId: remoteId,
          updatedAt: remoteUpdatedAt,
        );
        storage.saveReward(newReward);
      } else if (remoteUpdatedAt.isAfter(local.updatedAt)) {
        final updated = local.copyWith(
          status: remote['status'] as String?,
          timesRedeemed: remote['times_redeemed'] as int?,
          isArchived: remote['is_archived'] as bool?,
          cloudId: remoteId,
          updatedAt: remoteUpdatedAt,
        );
        storage.saveReward(updated);
      }
    }
  }

  Future<void> _mergeQuests(StorageService storage) async {
    final remoteList = await _supabase.fetchQuests();
    final localList = storage.getAllQuests();
    final localByCloudId = {for (var q in localList.where((q) => q.cloudId != null)) q.cloudId!: q};

    for (final remote in remoteList) {
      final remoteId = remote['id'] as String?;
      final remoteUpdatedAt = DateTime.tryParse(remote['updated_at'] ?? '') ?? DateTime(2000);
      final local = remoteId != null ? localByCloudId[remoteId] : null;

      if (local != null && remoteUpdatedAt.isAfter(local.updatedAt)) {
        final updated = local.copyWith(
          isCompleted: remote['is_completed'] as bool?,
          progress: (remote['progress'] as num?)?.toDouble(),
          cloudId: remoteId,
          updatedAt: remoteUpdatedAt,
        );
        storage.saveQuest(updated);
      }
    }
  }

  Future<void> _mergeBadges(StorageService storage) async {
    final remoteList = await _supabase.fetchBadges();
    final localList = storage.getAllBadges();
    final localByKey = {for (var b in localList) b.badgeKey: b};

    for (final remote in remoteList) {
      final remoteKey = remote['badge_key'] as String?;
      if (remoteKey == null) continue;

      final remoteUpdatedAt = DateTime.tryParse(remote['updated_at'] ?? '') ?? DateTime(2000);
      final local = localByKey[remoteKey];

      if (local != null && remoteUpdatedAt.isAfter(local.updatedAt)) {
        final isUnlocked = remote['is_unlocked'] as bool? ?? local.isUnlocked;
        final unlockedAtStr = remote['unlocked_at'] as String?;
        final updated = local.copyWith(
          isUnlocked: isUnlocked,
          unlockedAt: unlockedAtStr != null ? DateTime.tryParse(unlockedAtStr) : local.unlockedAt,
          cloudId: remote['id'] as String?,
          updatedAt: remoteUpdatedAt,
        );
        storage.saveBadge(updated);
      }
    }
  }
}
