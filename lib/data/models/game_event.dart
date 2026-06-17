import 'package:objectbox/objectbox.dart';

@Entity()
class GameEvent {
  @Id()
  int id = 0;

  String name;
  String description;
  String type; // 'double_xp', 'category_spotlight', 'half_cooldown'
  double multiplier; // e.g., 2.0 for double XP
  @Property(type: PropertyType.date)
  DateTime startAt;
  @Property(type: PropertyType.date)
  DateTime endAt;
  bool isActive;
  int? targetCategoryId; // Applicable only if type is 'category_spotlight'

  GameEvent({
    this.id = 0,
    required this.name,
    required this.description,
    required this.type,
    this.multiplier = 1.0,
    DateTime? startAt,
    DateTime? endAt,
    this.isActive = true,
    this.targetCategoryId,
  })  : startAt = startAt ?? DateTime.now(),
        endAt = endAt ?? DateTime.now().add(const Duration(days: 2));

  GameEvent copyWith({
    int? id,
    String? name,
    String? description,
    String? type,
    double? multiplier,
    DateTime? startAt,
    DateTime? endAt,
    bool? isActive,
    int? targetCategoryId,
  }) {
    return GameEvent(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      multiplier: multiplier ?? this.multiplier,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      isActive: isActive ?? this.isActive,
      targetCategoryId: targetCategoryId ?? this.targetCategoryId,
    );
  }
}
