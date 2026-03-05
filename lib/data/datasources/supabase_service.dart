import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:earnjoy/data/models/activity.dart';
import 'package:earnjoy/data/models/badge.dart';
import 'package:earnjoy/data/models/quest.dart';
import 'package:earnjoy/data/models/reward.dart';
import 'package:earnjoy/data/models/user.dart' as ej_user;

/// Thin wrapper around the Supabase client that provides typed CRUD methods
/// for all syncable entities. Must call [SupabaseService.initialize()] before use.
class SupabaseService {
  SupabaseClient get _client => Supabase.instance.client;

  // ─── Auth ─────────────────────────────────────────────────────────────────

  /// The currently signed-in Supabase user (from gotrue).
  User? get currentAuthUser => _client.auth.currentUser;
  bool get isSignedIn => currentAuthUser != null;
  bool get isAnonymous =>
      currentAuthUser?.isAnonymous ?? false;

  /// Signs in anonymously — creates a temporary account tied to this device.
  Future<void> signInAnonymous() async {
    await _client.auth.signInAnonymously();
  }

  /// Creates a new account with email and password.
  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return _client.auth.signUp(email: email, password: password);
  }

  /// Signs in with existing email/password credentials.
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ─── User ─────────────────────────────────────────────────────────────────

  Future<void> upsertUser(ej_user.User user) async {
    final uid = currentAuthUser?.id;
    if (uid == null) return;
    await _client.from('earnjoy_users').upsert({
      'id': user.cloudId ?? _newId(),
      'user_id': uid,
      'name': user.name,
      'point_balance': user.pointBalance,
      'streak': user.streak,
      'xp': user.xp,
      'updated_at': user.updatedAt.toIso8601String(),
    }, onConflict: 'user_id');
  }

  Future<Map<String, dynamic>?> fetchUser() async {
    final uid = currentAuthUser?.id;
    if (uid == null) return null;
    final res = await _client
        .from('earnjoy_users')
        .select()
        .eq('user_id', uid)
        .maybeSingle();
    return res;
  }

  // ─── Activities ───────────────────────────────────────────────────────────

  Future<void> upsertActivities(List<Activity> activities) async {
    final uid = currentAuthUser?.id;
    if (uid == null || activities.isEmpty) return;
    final rows = activities.map((a) => {
      'id': a.cloudId ?? _newId(),
      'user_id': uid,
      'title': a.title,
      'category_name': a.category.target?.name ?? 'Other',
      'duration_minutes': a.durationMinutes,
      'points': a.points,
      'created_at': a.createdAt.toIso8601String(),
      'updated_at': a.updatedAt.toIso8601String(),
    }).toList();
    await _client.from('earnjoy_activities').upsert(rows);
  }

  Future<List<Map<String, dynamic>>> fetchActivities() async {
    final uid = currentAuthUser?.id;
    if (uid == null) return [];
    return List<Map<String, dynamic>>.from(
      await _client.from('earnjoy_activities').select().eq('user_id', uid),
    );
  }

  // ─── Rewards ──────────────────────────────────────────────────────────────

  Future<void> upsertRewards(List<Reward> rewards) async {
    final uid = currentAuthUser?.id;
    if (uid == null || rewards.isEmpty) return;
    final rows = rewards
        .where((r) => !r.isTemplate) // templates are seeded locally, skip
        .map((r) => {
              'id': r.cloudId ?? _newId(),
              'user_id': uid,
              'name': r.name,
              'point_cost': r.pointCost,
              'status': r.status,
              'category': r.category,
              'icon_emoji': r.iconEmoji,
              'recurrence_type': r.recurrenceType,
              'times_redeemed': r.timesRedeemed,
              'is_archived': r.isArchived,
              'updated_at': r.updatedAt.toIso8601String(),
            })
        .toList();
    if (rows.isEmpty) return;
    await _client.from('earnjoy_rewards').upsert(rows);
  }

  Future<List<Map<String, dynamic>>> fetchRewards() async {
    final uid = currentAuthUser?.id;
    if (uid == null) return [];
    return List<Map<String, dynamic>>.from(
      await _client.from('earnjoy_rewards').select().eq('user_id', uid),
    );
  }

  // ─── Quests ───────────────────────────────────────────────────────────────

  Future<void> upsertQuests(List<Quest> quests) async {
    final uid = currentAuthUser?.id;
    if (uid == null || quests.isEmpty) return;
    final rows = quests.map((q) => {
          'id': q.cloudId ?? _newId(),
          'user_id': uid,
          'title': q.title,
          'type': q.type,
          'is_completed': q.isCompleted,
          'progress': q.progress,
          'expires_at': q.expiresAt.toIso8601String(),
          'updated_at': q.updatedAt.toIso8601String(),
        }).toList();
    await _client.from('earnjoy_quests').upsert(rows);
  }

  Future<List<Map<String, dynamic>>> fetchQuests() async {
    final uid = currentAuthUser?.id;
    if (uid == null) return [];
    return List<Map<String, dynamic>>.from(
      await _client.from('earnjoy_quests').select().eq('user_id', uid),
    );
  }

  // ─── Badges ───────────────────────────────────────────────────────────────

  Future<void> upsertBadges(List<Badge> badges) async {
    final uid = currentAuthUser?.id;
    if (uid == null || badges.isEmpty) return;
    final rows = badges.map((b) => {
          'id': b.cloudId ?? _newId(),
          'user_id': uid,
          'badge_key': b.badgeKey,
          'is_unlocked': b.isUnlocked,
          'unlocked_at': b.unlockedAt?.toIso8601String(),
          'updated_at': b.updatedAt.toIso8601String(),
        }).toList();
    await _client.from('earnjoy_badges').upsert(rows);
  }

  Future<List<Map<String, dynamic>>> fetchBadges() async {
    final uid = currentAuthUser?.id;
    if (uid == null) return [];
    return List<Map<String, dynamic>>.from(
      await _client.from('earnjoy_badges').select().eq('user_id', uid),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Generates a v4-like UUID string using the current time for uniqueness.
  /// Real UUID generation would need the `uuid` package; this is sufficient
  /// for our purposes since Supabase will accept any stable unique string.
  String _newId() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    // Simple hex-based ID: not RFC4122 but unique enough for this use case.
    return 'ej-${ts.toRadixString(16)}-${(ts % 0xFFFF).toRadixString(16)}';
  }
}
