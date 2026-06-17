import 'package:objectbox/objectbox.dart';

/// Status values for a GroupChallenge.
class GroupChallengeStatus {
  static const active = 'active';
  static const completed = 'completed';
  static const failed = 'failed';
}

@Entity()
class GroupChallenge {
  @Id()
  int id;

  String name;
  String description;
  double targetPoints;
  double currentPoints;

  String status; // GroupChallengeStatus constants
  String membersJson; // JSON array of member names e.g. '["Reza","Budi"]'

  @Property(type: PropertyType.date)
  DateTime startAt;

  @Property(type: PropertyType.date)
  DateTime endAt;

  GroupChallenge({
    this.id = 0,
    required this.name,
    this.description = '',
    required this.targetPoints,
    this.currentPoints = 0.0,
    this.status = GroupChallengeStatus.active,
    this.membersJson = '[]',
    DateTime? startAt,
    DateTime? endAt,
  })  : startAt = startAt ?? DateTime.now(),
        endAt = endAt ?? DateTime.now().add(const Duration(days: 7));

  GroupChallenge copyWith({
    int? id,
    String? name,
    String? description,
    double? targetPoints,
    double? currentPoints,
    String? status,
    String? membersJson,
    DateTime? startAt,
    DateTime? endAt,
  }) {
    return GroupChallenge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      targetPoints: targetPoints ?? this.targetPoints,
      currentPoints: currentPoints ?? this.currentPoints,
      status: status ?? this.status,
      membersJson: membersJson ?? this.membersJson,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
    );
  }

  bool get isActive => status == GroupChallengeStatus.active;
  bool get isCompleted => status == GroupChallengeStatus.completed;
  double get progress => targetPoints > 0 ? (currentPoints / targetPoints).clamp(0.0, 1.0) : 0.0;
  int get daysRemaining => endAt.difference(DateTime.now()).inDays.clamp(0, 999);
}
