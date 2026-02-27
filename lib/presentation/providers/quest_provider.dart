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

  QuestProvider(this._storage) {
    _questService = QuestService(_storage);
    _questService.ensureDailyQuests();
    loadQuests();
  }
  
  List<Quest> get dailyQuests => List.unmodifiable(_dailyQuests);

  void setUserProvider(UserProvider userProvider) {
    _userProvider = userProvider;
  }

  void loadQuests() {
    _dailyQuests = _questService.getDailyQuests();
    notifyListeners();
  }

  /// Called after an activity is successfully logged
  void onActivityLogged(Activity activity) {
    _questService.evaluateActivity(activity);
    
    // Check if any quest was completed that wasn't before
    // To do this properly, we refresh the quests and find any that are now completed
    // Or we let QuestService handle completion processing. For MVP, we will directly check.
    
    final allQuests = _storage.getAllQuests();
    bool freshlyCompleted = false;
    double totalBonus = 0;
    
    for (final quest in allQuests) {
      if (quest.type == 'daily' && quest.isCompleted && !quest.progress.isNaN) {
        // If completed, check if we haven't rewarded yet.
        // We'll mark progress as NaN or just rely on a new field `isRewarded`.
        // To avoid schema migration again, we can just consume it by setting progress = 2.0 or deleting it.
        // Let's do something simpler: check _dailyQuests which we loaded previously.
        final wasInList = _dailyQuests.any((q) => q.id == quest.id);
        if (wasInList) {
          // It was active before, now it's completed
          freshlyCompleted = true;
          totalBonus += quest.bonusPoints;
          // Delete or mark invisible so it doesn't get rewarded again
          _storage.deleteQuest(quest.id);
        }
      }
    }
    
    if (freshlyCompleted && totalBonus > 0 && _userProvider != null) {
      // Award points
      _storage.saveTransaction(Transaction(type: TransactionType.earn, amount: totalBonus, label: 'Quest Completion Bonus'));
      _userProvider!.updateAfterActivity(totalBonus);
      // Let UI know we completed quests (maybe via callback or just state change)
    }

    loadQuests(); // Refresh
  }
}
