import 'package:objectbox/objectbox.dart';

@Entity()
class Badge {
  @Id()
  int id;

  @Unique()
  String badgeKey;

  String name;
  String description;
  String icon;
  String category;
  int rarity; // 1=Common, 2=Rare, 3=Epic, 4=Legendary
  bool isUnlocked;

  @Property(type: PropertyType.date)
  DateTime? unlockedAt;

  String conditionJson;

  // Cloud Sync
  String? cloudId;
  @Property(type: PropertyType.date)
  DateTime updatedAt;

  Badge({
    this.id = 0,
    required this.badgeKey,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    this.rarity = 1,
    this.isUnlocked = false,
    this.unlockedAt,
    required this.conditionJson,
    this.cloudId,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Badge copyWith({
    int? id,
    String? badgeKey,
    String? name,
    String? description,
    String? icon,
    String? category,
    int? rarity,
    bool? isUnlocked,
    DateTime? unlockedAt,
    String? conditionJson,
    String? cloudId,
    bool clearCloudId = false,
    DateTime? updatedAt,
  }) {
    return Badge(
      id: id ?? this.id,
      badgeKey: badgeKey ?? this.badgeKey,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      rarity: rarity ?? this.rarity,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      conditionJson: conditionJson ?? this.conditionJson,
      cloudId: clearCloudId ? null : (cloudId ?? this.cloudId),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
