import 'package:objectbox/objectbox.dart';

@Entity()
class Category {
  @Id()
  int id;

  String name;
  double weight;
  bool isNegative;
  String icon;

  Category({
    this.id = 0,
    required this.name,
    required this.weight,
    this.isNegative = false,
    required this.icon,
  });

  Category copyWith({int? id, String? name, double? weight, bool? isNegative, String? icon}) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      weight: weight ?? this.weight,
      isNegative: isNegative ?? this.isNegative,
      icon: icon ?? this.icon,
    );
  }
}
