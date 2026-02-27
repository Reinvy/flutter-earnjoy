import 'package:flutter/foundation.dart';
import 'package:earnjoy/data/datasources/storage_service.dart';
import 'package:earnjoy/data/models/habit_stack.dart';
import 'package:earnjoy/data/models/stack_item.dart';
import 'package:earnjoy/presentation/providers/activity_provider.dart';
import 'package:earnjoy/presentation/providers/user_provider.dart';

class HabitStackProvider extends ChangeNotifier {
  final StorageService _storage;
  final UserProvider _userProvider;
  final ActivityProvider _activityProvider;

  List<HabitStack> _habitStacks = [];

  List<HabitStack> get habitStacks => _habitStacks;

  // Active stack tracking
  HabitStack? _activeStack;
  int _activeItemIndex = 0;
  DateTime? _stackStartTime;

  HabitStackProvider(this._storage, this._userProvider, this._activityProvider) {
    loadStacks();
  }

  void loadStacks() {
    _habitStacks = _storage.getAllHabitStacks();
    notifyListeners();
  }

  HabitStack? get activeStack => _activeStack;
  int get activeItemIndex => _activeItemIndex;
  
  StackItem? get currentActiveItem {
    if (_activeStack == null || _activeItemIndex >= _activeStack!.items.length) {
      return null;
    }
    // Items should be sorted by order
    final sortedItems = _activeStack!.items.toList()..sort((a, b) => a.order.compareTo(b.order));
    return sortedItems[_activeItemIndex];
  }

  void startStack(HabitStack stack) {
    _activeStack = stack;
    _activeItemIndex = 0;
    _stackStartTime = DateTime.now();
    
    // Reset completed status for items
    for (var item in _activeStack!.items) {
      item.isCompleted = false;
      _storage.saveStackItem(item);
    }
    notifyListeners();
  }

  void completeCurrentItem() {
    if (_activeStack == null || currentActiveItem == null) return;

    final item = currentActiveItem!;
    item.isCompleted = true;
    _storage.saveStackItem(item);

    // Log the activity
    _activityProvider.logActivity(
      title: item.activityTitle,
      categoryId: item.category.targetId,
      durationMinutes: item.durationMinutes,
      // Stack items might give standard points based on duration,
      // or we just give the stack bonus at the end
    );

    _activeItemIndex++;

    // Did we finish the stack?
    if (_activeItemIndex >= _activeStack!.items.length) {
      _finishStack();
    } else {
      notifyListeners();
    }
  }

  void _finishStack() {
    if (_activeStack == null) return;

    // Award bonus points
    if (_activeStack!.bonusPoints > 0) {
      _userProvider.updateBalance(_activeStack!.bonusPoints.toDouble());
    }

    // Update streak (simplified logic, just incrementing for now)
    final now = DateTime.now();
    bool shouldIncrementStreak = false;

    if (_activeStack!.lastCompletedAt == null) {
      shouldIncrementStreak = true;
    } else {
      final diff = now.difference(_activeStack!.lastCompletedAt!).inDays;
      if (diff == 1) { // Next day
        shouldIncrementStreak = true;
      } else if (diff > 1) { // Missed a day
        _activeStack!.streakDays = 0;
        shouldIncrementStreak = true; // Started new streak
      }
    }

    if (shouldIncrementStreak) {
      _activeStack!.streakDays++;
    }
    
    _activeStack!.lastCompletedAt = now;
    _storage.saveHabitStack(_activeStack!);
    
    _activeStack = null;
    _activeItemIndex = 0;
    
    loadStacks();
  }

  void cancelStack() {
    _activeStack = null;
    _activeItemIndex = 0;
    notifyListeners();
  }

  // Builder Methods
  
  void deleteHabitStack(int id) {
    _storage.deleteHabitStack(id);
    loadStacks();
  }

  void saveCustomStack(HabitStack stack) {
    _storage.saveHabitStack(stack);
    loadStacks();
  }
}
