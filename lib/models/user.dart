import 'package:objectbox/objectbox.dart';

@Entity()
class User {
  @Id()
  int id = 0;

  String name;
  double pointBalance;
  int streak;
  double monthlyBudget;
  double burnoutScore;
  double adjustmentFactor;
  double disciplineScore;
  @Property(type: PropertyType.date)
  DateTime lastActivityDate;

  User({
    this.id = 0,
    this.name = 'User',
    this.pointBalance = 0.0,
    this.streak = 0,
    this.monthlyBudget = 10000.0,
    this.burnoutScore = 0.0,
    this.adjustmentFactor = 1.0,
    this.disciplineScore = 0.0,
    DateTime? lastActivityDate,
  }) : lastActivityDate = lastActivityDate ?? DateTime(2000);

  User copyWith({
    int? id,
    String? name,
    double? pointBalance,
    int? streak,
    double? monthlyBudget,
    double? burnoutScore,
    double? adjustmentFactor,
    double? disciplineScore,
    DateTime? lastActivityDate,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      pointBalance: pointBalance ?? this.pointBalance,
      streak: streak ?? this.streak,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      burnoutScore: burnoutScore ?? this.burnoutScore,
      adjustmentFactor: adjustmentFactor ?? this.adjustmentFactor,
      disciplineScore: disciplineScore ?? this.disciplineScore,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
    );
  }
}
