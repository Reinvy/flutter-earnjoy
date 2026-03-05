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

  // Cloud Sync
  String? cloudId;
  @Property(type: PropertyType.date)
  DateTime updatedAt;

  Activity({
    this.id = 0,
    required this.title,
    required this.durationMinutes,
    this.points = 0.0,
    DateTime? createdAt,
    this.cloudId,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Activity copyWith({
    int? id,
    String? title,
    int? durationMinutes,
    double? points,
    DateTime? createdAt,
    String? cloudId,
    bool clearCloudId = false,
    DateTime? updatedAt,
  }) {
    return Activity(
      id: id ?? this.id,
      title: title ?? this.title,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
      cloudId: clearCloudId ? null : (cloudId ?? this.cloudId),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
