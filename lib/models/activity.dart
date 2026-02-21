import 'package:objectbox/objectbox.dart';

@Entity()
class Activity {
  @Id()
  int id = 0;

  String title;
  String category;
  int durationMinutes;
  double points;
  @Property(type: PropertyType.date)
  DateTime createdAt;

  Activity({
    this.id = 0,
    required this.title,
    required this.category,
    required this.durationMinutes,
    this.points = 0.0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Activity copyWith({
    int? id,
    String? title,
    String? category,
    int? durationMinutes,
    double? points,
    DateTime? createdAt,
  }) {
    return Activity(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
