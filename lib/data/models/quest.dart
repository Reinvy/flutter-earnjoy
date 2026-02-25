import 'package:objectbox/objectbox.dart';

@Entity()
class Quest {
  @Id()
  int id;

  String title;
  String description;
  int targetCount;
  int currentCount;
  double bonusPoints;
  bool isCompleted;

  @Property(type: PropertyType.date)
  DateTime date;

  Quest({
    this.id = 0,
    required this.title,
    required this.description,
    required this.targetCount,
    this.currentCount = 0,
    required this.bonusPoints,
    this.isCompleted = false,
    required this.date,
  });

  Quest copyWith({
    int? id,
    String? title,
    String? description,
    int? targetCount,
    int? currentCount,
    double? bonusPoints,
    bool? isCompleted,
    DateTime? date,
  }) {
    return Quest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      bonusPoints: bonusPoints ?? this.bonusPoints,
      isCompleted: isCompleted ?? this.isCompleted,
      date: date ?? this.date,
    );
  }
}
