import 'package:objectbox/objectbox.dart';
import 'package:earnjoy/data/models/stack_item.dart';

@Entity()
class HabitStack {
  @Id()
  int id = 0;

  String name;
  String description;
  bool isTemplate;
  int bonusPoints;
  int streakDays;

  @Property(type: PropertyType.date)
  DateTime? lastCompletedAt;

  @Backlink()
  final items = ToMany<StackItem>();

  HabitStack({
    this.id = 0,
    required this.name,
    required this.description,
    this.isTemplate = false,
    this.bonusPoints = 0,
    this.streakDays = 0,
    this.lastCompletedAt,
  });
}
