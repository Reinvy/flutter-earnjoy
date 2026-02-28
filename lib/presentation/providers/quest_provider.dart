import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:earnjoy/data/models/activity.dart';
import 'package:earnjoy/data/models/quest.dart';
import 'package:earnjoy/data/models/transaction.dart';
import 'package:earnjoy/domain/usecases/quest_service.dart';
import 'package:earnjoy/data/datasources/storage_service.dart';
import 'user_provider.dart';

class QuestProvider extends ChangeNotifier {
  final StorageService _storage;
  late final QuestService _questService;
  UserProvider? _userProvider;

  List<Quest> _dailyQuests = [];

  // Stream to notify UI about newly completed quests (for banner/toast/confetti)
  final _completionController = StreamController<List<Quest>>.broadcast();
  Stream<List<Quest>> get onQuestsCompleted => _completionController.stream;

  QuestProvider(this._storage) {
    _questService = QuestService(_storage);
    _questService.ensureDailyQuests();
    _loadQuests();
  }

  List<Quest> get dailyQuests => List.unmodifiable(_dailyQuests);

  void setUserProvider(UserProvider userProvider) {
    _userProvider = userProvider;
  }

  void _loadQuests() {
    _dailyQuests = _questService.getDailyQuests();
    notifyListeners();
  }

  /// Called after an activity is successfully logged.
  /// Evaluates quests, distributes bonus points for any that were just completed.
  void onActivityLogged(Activity activity) {
    final result = _questService.evaluateActivity(activity);

    if (result.hasCompletions) {
      final completed = result.justCompleted;
      double totalBonus = 0;

      for (final quest in completed) {
        totalBonus += quest.bonusPoints;
        // Mark as rewarded so it's archived (won't appear or be rewarded again)
        _questService.markRewarded(quest);
      }

      if (totalBonus > 0 && _userProvider != null) {
        _storage.saveTransaction(
          Transaction(
            type: TransactionType.earn,
            amount: totalBonus,
            label: '🗡️ Quest Bonus',
          ),
        );
        _userProvider!.updateBalance(totalBonus);
      }

      // Notify UI for visual feedback (confetti/snackbar)
      _completionController.add(completed);
    }

    _loadQuests();
  }

  @override
  void dispose() {
    _completionController.close();
    super.dispose();
  }
}
