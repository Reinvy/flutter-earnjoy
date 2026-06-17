import 'package:earnjoy/data/datasources/storage_service.dart';
import 'package:earnjoy/data/models/game_event.dart';

class EventService {
  final StorageService _storage;

  EventService(this._storage);

  List<GameEvent> getActiveEvents() {
    return _storage.getActiveEvents();
  }

  /// Calculates the total multiplier from active events for a given category.
  double getActiveMultiplierForCategory(int categoryId) {
    final activeEvents = getActiveEvents();
    double multiplier = 1.0;
    
    for (final event in activeEvents) {
      if (event.type == 'double_xp') {
        multiplier *= event.multiplier;
      } else if (event.type == 'category_spotlight' && event.targetCategoryId == categoryId) {
        multiplier *= event.multiplier;
      }
    }
    
    return multiplier;
  }
}
