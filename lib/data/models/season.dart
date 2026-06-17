import 'package:objectbox/objectbox.dart';

@Entity()
class Season {
  @Id()
  int id = 0;

  String name;
  String themeKey;
  @Property(type: PropertyType.date)
  DateTime startAt;
  @Property(type: PropertyType.date)
  DateTime endAt;
  bool isActive;
  String milestonesJson; // list of milestone rewards serialized

  Season({
    this.id = 0,
    required this.name,
    this.themeKey = "cosmic",
    DateTime? startAt,
    DateTime? endAt,
    this.isActive = true,
    this.milestonesJson = "[]",
  })  : startAt = startAt ?? DateTime.now(),
        endAt = endAt ?? DateTime.now().add(const Duration(days: 90));

  Season copyWith({
    int? id,
    String? name,
    String? themeKey,
    DateTime? startAt,
    DateTime? endAt,
    bool? isActive,
    String? milestonesJson,
  }) {
    return Season(
      id: id ?? this.id,
      name: name ?? this.name,
      themeKey: themeKey ?? this.themeKey,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      isActive: isActive ?? this.isActive,
      milestonesJson: milestonesJson ?? this.milestonesJson,
    );
  }
}
