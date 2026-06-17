import 'package:objectbox/objectbox.dart';
import 'package:earnjoy/data/models/season.dart';
import 'package:earnjoy/data/models/user.dart';

@Entity()
class SeasonProgress {
  @Id()
  int id = 0;

  final season = ToOne<Season>();
  final user = ToOne<User>();
  
  double xpEarned;       // XP in this current season
  int rank;              // Current rank relative to leaderboard
  int milestoneReached;  // Highest index of unlocked milestone
  
  SeasonProgress({
    this.id = 0,
    this.xpEarned = 0.0,
    this.rank = 0,
    this.milestoneReached = -1, // -1 means none
  });

  SeasonProgress copyWith({
    int? id,
    double? xpEarned,
    int? rank,
    int? milestoneReached,
  }) {
    return SeasonProgress(
      id: id ?? this.id,
      xpEarned: xpEarned ?? this.xpEarned,
      rank: rank ?? this.rank,
      milestoneReached: milestoneReached ?? this.milestoneReached,
    );
  }
}
