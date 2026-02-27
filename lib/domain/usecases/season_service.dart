import 'package:earnjoy/data/datasources/storage_service.dart';
import 'package:earnjoy/data/models/season.dart';
import 'package:earnjoy/data/models/season_progress.dart';

class SeasonService {
  final StorageService _storage;

  SeasonService(this._storage);

  Season? getActiveSeason() {
    return _storage.getActiveSeason();
  }

  SeasonProgress? getProgressForUser(int userId, int seasonId) {
    return _storage.getSeasonProgressForUser(userId, seasonId);
  }

  /// Adds XP to the user's progress in the active season if there is one.
  void addXpToActiveSeason(int userId, double xp) {
    final activeSeason = getActiveSeason();
    if (activeSeason == null) return;

    var progress = getProgressForUser(userId, activeSeason.id);
    if (progress == null) {
      progress = SeasonProgress(xpEarned: xp, rank: 0, milestoneReached: -1);
      progress.user.targetId = userId;
      progress.season.targetId = activeSeason.id;
    } else {
      progress.xpEarned += xp;
    }

    _storage.saveSeasonProgress(progress);
  }
}
