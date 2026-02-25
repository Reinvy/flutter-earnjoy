import 'package:objectbox/objectbox.dart';

@Entity()
class Badge {
  @Id()
  int id;

  String name;
  String description;
  String icon;

  @Property(type: PropertyType.date)
  DateTime? unlockedAt;

  Badge({
    this.id = 0,
    required this.name,
    required this.description,
    required this.icon,
    this.unlockedAt,
  });

  Badge copyWith({int? id, String? name, String? description, String? icon, DateTime? unlockedAt}) {
    return Badge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}
