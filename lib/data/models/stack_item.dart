import 'package:objectbox/objectbox.dart';
import 'package:earnjoy/data/models/habit_stack.dart';
import 'package:earnjoy/data/models/category.dart';

@Entity()
class StackItem {
  @Id()
  int id = 0;

  String activityTitle;
  int durationMinutes; // Time needed to finish the item
  int order; // The ordering constraint
  bool isCompleted;

  final stack = ToOne<HabitStack>();
  final category = ToOne<Category>();

  StackItem({
    this.id = 0,
    required this.activityTitle,
    required this.durationMinutes,
    required this.order,
    this.isCompleted = false,
  });
}
