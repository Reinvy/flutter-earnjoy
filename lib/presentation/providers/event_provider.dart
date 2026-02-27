import 'package:flutter/foundation.dart';
import 'package:earnjoy/data/models/game_event.dart';
import 'package:earnjoy/domain/usecases/event_service.dart';
import 'package:earnjoy/data/datasources/storage_service.dart';

class EventProvider extends ChangeNotifier {
  late final EventService _eventService;

  List<GameEvent> _activeEvents = [];

  EventProvider(StorageService storage) {
    _eventService = EventService(storage);
    loadActiveEvents();
  }

  List<GameEvent> get activeEvents => List.unmodifiable(_activeEvents);

  void loadActiveEvents() {
    _activeEvents = _eventService.getActiveEvents();
    notifyListeners();
  }

  double getMultiplierForCategory(int categoryId) {
    return _eventService.getActiveMultiplierForCategory(categoryId);
  }
}
