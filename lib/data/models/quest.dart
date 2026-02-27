import 'package:objectbox/objectbox.dart';

@Entity()
class Quest {
  @Id()
  int id;

  String title;
  String description;
  String type; // 'daily' | 'weekly' | 'epic' | 'flash' | 'milestone'
  String conditionType; // 'log_count' | 'point_target' | 'category_combo' | 'streak'
  String conditionJson; // serialized condition params
  int bonusPoints;
  String? rewardBadgeId;

  @Property(type: PropertyType.date)
  DateTime expiresAt;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  bool isCompleted;
  double progress; // 0.0 - 1.0

  Quest({
    this.id = 0,
    required this.title,
    required this.description,
    required this.type,
    required this.conditionType,
    this.conditionJson = '{}',
    required this.bonusPoints,
    this.rewardBadgeId,
    required this.expiresAt,
    required this.createdAt,
    this.isCompleted = false,
    this.progress = 0.0,
  });

  Quest copyWith({
    int? id,
    String? title,
    String? description,
    String? type,
    String? conditionType,
    String? conditionJson,
    int? bonusPoints,
    String? rewardBadgeId,
    DateTime? expiresAt,
    DateTime? createdAt,
    bool? isCompleted,
    double? progress,
  }) {
    return Quest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      conditionType: conditionType ?? this.conditionType,
      conditionJson: conditionJson ?? this.conditionJson,
      bonusPoints: bonusPoints ?? this.bonusPoints,
      rewardBadgeId: rewardBadgeId ?? this.rewardBadgeId,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      progress: progress ?? this.progress,
    );
  }
}
