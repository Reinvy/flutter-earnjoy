import 'dart:convert';
import 'package:earnjoy/data/datasources/storage_service.dart';
import 'package:earnjoy/data/models/activity.dart';
import 'package:earnjoy/data/models/quest.dart';

/// Result of evaluating quests after logging an activity.
class QuestEvaluationResult {
  final List<Quest> justCompleted;
  QuestEvaluationResult(this.justCompleted);
  bool get hasCompletions => justCompleted.isNotEmpty;
}

class QuestService {
  final StorageService _storage;

  QuestService(this._storage);

  /// Get quests that are still active (not expired, not rewarded).
  /// progress < 2.0 means not yet rewarded (2.0 = sentinel "rewarded & done").
  List<Quest> getDailyQuests() {
    final now = DateTime.now();
    return _storage.getAllQuests().where((q) {
      return q.type == 'daily' &&
          q.expiresAt.isAfter(now) &&
          q.progress < 2.0; // 2.0 = rewarded sentinel
    }).toList();
  }

  /// Ensure there are active daily quests for today. Generates if none exist.
  void ensureDailyQuests() {
    final activeDailies = getDailyQuests();
    if (activeDailies.isNotEmpty) return;

    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final templates = [
      _makeQuest(
        title: '⚡ Pejuang Hari Ini',
        description: 'Log setidaknya 1 aktivitas hari ini',
        conditionType: 'log_count',
        conditionJson: jsonEncode({'count': 1}),
        bonusPoints: 50,
        createdAt: now,
        expiresAt: endOfDay,
      ),
      _makeQuest(
        title: '🔥 Trifecta Hari Ini',
        description: 'Log 3 aktivitas dalam satu hari',
        conditionType: 'log_count',
        conditionJson: jsonEncode({'count': 3}),
        bonusPoints: 150,
        createdAt: now,
        expiresAt: endOfDay,
      ),
    ];

    for (final q in templates) {
      _storage.saveQuest(q);
    }
  }

  Quest _makeQuest({
    required String title,
    required String description,
    required String conditionType,
    required String conditionJson,
    required double bonusPoints,
    required DateTime createdAt,
    required DateTime expiresAt,
  }) {
    return Quest(
      title: title,
      description: description,
      type: 'daily',
      conditionType: conditionType,
      conditionJson: conditionJson,
      bonusPoints: bonusPoints,
      createdAt: createdAt,
      expiresAt: expiresAt,
    );
  }

  /// Evaluates all active quests against current logged activities.
  /// Returns list of quests that were JUST completed in this call.
  QuestEvaluationResult evaluateActivity(Activity activity) {
    final now = DateTime.now();
    final activeQuests = _storage.getAllQuests().where((q) {
      return q.expiresAt.isAfter(now) && !q.isCompleted && q.progress < 2.0;
    }).toList();

    final justCompleted = <Quest>[];

    for (final quest in activeQuests) {
      _updateQuestProgress(quest);
      if (quest.isCompleted) {
        justCompleted.add(quest);
      }
    }

    return QuestEvaluationResult(justCompleted);
  }

  void _updateQuestProgress(Quest quest) {
    final condition = jsonDecode(quest.conditionJson) as Map<String, dynamic>;

    if (quest.conditionType == 'log_count') {
      final required = condition['count'] as int;
      final logsToday = _storage.getTodayActivities().length;

      final newProgress = (logsToday / required).clamp(0.0, 1.0);
      quest.progress = newProgress;

      if (newProgress >= 1.0) {
        quest.isCompleted = true;
        // Keep progress at exactly 1.0 until reward is claimed;
        // After reward is paid, caller sets progress = 2.0 to dismiss.
      }
      _storage.saveQuest(quest);
    }
    // Extensible: add 'point_target', 'category_combo', 'streak' types here
  }

  /// Marks a quest as rewarded so it won't appear or be rewarded again.
  void markRewarded(Quest quest) {
    quest.progress = 2.0; // Sentinel: "rewarded & archived"
    _storage.saveQuest(quest);
  }
}
