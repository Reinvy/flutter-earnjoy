import 'package:flutter/foundation.dart';
import 'package:earnjoy/data/models/season.dart';
import 'package:earnjoy/data/models/season_progress.dart';
import 'package:earnjoy/domain/usecases/season_service.dart';
import 'package:earnjoy/data/datasources/storage_service.dart';

class SeasonProvider extends ChangeNotifier {
  late final SeasonService _seasonService;
  
  Season? _activeSeason;
  SeasonProgress? _userProgress;

  SeasonProvider(StorageService storage) {
    _seasonService = SeasonService(storage);
  }

  Season? get activeSeason => _activeSeason;
  SeasonProgress? get userProgress => _userProgress;

  void loadSeasonData(int userId) {
    _activeSeason = _seasonService.getActiveSeason();
    if (_activeSeason != null) {
      _userProgress = _seasonService.getProgressForUser(userId, _activeSeason!.id);
    } else {
      _userProgress = null;
    }
    notifyListeners();
  }

  void refreshProgress(int userId) {
    if (_activeSeason != null) {
      _userProgress = _seasonService.getProgressForUser(userId, _activeSeason!.id);
      notifyListeners();
    }
  }
}
