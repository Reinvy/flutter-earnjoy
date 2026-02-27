import 'dart:convert';
import 'package:earnjoy/data/datasources/storage_service.dart';
import 'package:earnjoy/data/models/activity.dart';
import 'package:earnjoy/data/models/quest.dart';

class QuestService {
  final StorageService _storage;

  QuestService(this._storage);

  /// Get quests that are active today
  List<Quest> getDailyQuests() {
    final now = DateTime.now();
    return _storage.getAllQuests().where((q) {
      return q.type == 'daily' && q.expiresAt.isAfter(now) && !q.isCompleted;
    }).toList();
  }

  /// Ensure there are active daily quests. If not, generate some.
  void ensureDailyQuests() {
    final activeDailies = getDailyQuests();
    if (activeDailies.isNotEmpty) return;

    // Generate new daily quests
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final quest1 = Quest(
      title: 'Pejuang Pagi',
      description: 'Log aktivitas apapun hari ini',
      type: 'daily',
      conditionType: 'log_count',
      conditionJson: jsonEncode({'count': 1}),
      bonusPoints: 50,
      createdAt: now,
      expiresAt: endOfDay,
    );

    final quest2 = Quest(
      title: 'Trifecta Hari Ini',
      description: 'Log 3 aktivitas berbeda hari ini',
      type: 'daily',
      conditionType: 'log_count',
      conditionJson: jsonEncode({'count': 3}),
      bonusPoints: 150,
      createdAt: now,
      expiresAt: endOfDay,
    );

    _storage.saveQuest(quest1);
    _storage.saveQuest(quest2);
  }

  /// Evaluates an activity against all active quests
  void evaluateActivity(Activity activity) {
    final activeQuests = _storage.getAllQuests().where((q) {
      return q.expiresAt.isAfter(DateTime.now()) && !q.isCompleted;
    }).toList();

    for (final quest in activeQuests) {
      _evaluateQuestCondition(quest, activity);
    }
  }

  void _evaluateQuestCondition(Quest quest, Activity activity) {
    final condition = jsonDecode(quest.conditionJson) as Map<String, dynamic>;

    if (quest.conditionType == 'log_count') {
      final requiredCount = condition['count'] as int;
      
      // Increment progress simply by 1 log for now. Advanced logic would count today's logs.
      // Better to check today's actual logs if the rule is strict.
      final logsToday = _storage.getTodayActivities().length;
      
      double newProgress = logsToday / requiredCount;
      if (newProgress > 1.0) newProgress = 1.0;

      quest.progress = newProgress;
      
      if (quest.progress >= 1.0) {
        quest.isCompleted = true;
      }
      _storage.saveQuest(quest);
    }
    // More condition types: point_target, category_combo, streak can be added here
  }
}
