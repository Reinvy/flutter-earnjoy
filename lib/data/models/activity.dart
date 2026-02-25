import 'package:objectbox/objectbox.dart';
import 'package:earnjoy/data/models/category.dart';

@Entity()
class Activity {
  @Id()
  int id = 0;

  String title;
  final category = ToOne<Category>();
  int durationMinutes;
  double points;
  @Property(type: PropertyType.date)
  DateTime createdAt;

  Activity({
    this.id = 0,
    required this.title,
    required this.durationMinutes,
    this.points = 0.0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Activity copyWith({
    int? id,
    String? title,
    int? durationMinutes,
    double? points,
    DateTime? createdAt,
  }) {
    return Activity(
      id: id ?? this.id,
      title: title ?? this.title,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
