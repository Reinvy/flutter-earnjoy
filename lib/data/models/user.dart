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
  double xp;
  @Property(type: PropertyType.date)
  DateTime lastActivityDate;

  // Onboarding fields
  bool onboardingDone;
  double income;
  double rewardPercentage;

  // Weekly difficulty adjustment tracking
  @Property(type: PropertyType.date)
  DateTime lastWeeklyAdjustmentDate;

  User({
    this.id = 0,
    this.name = 'User',
    this.pointBalance = 0.0,
    this.streak = 0,
    this.monthlyBudget = 10000.0,
    this.burnoutScore = 0.0,
    this.adjustmentFactor = 1.0,
    this.disciplineScore = 0.0,
    this.xp = 0.0,
    DateTime? lastActivityDate,
    this.onboardingDone = false,
    this.income = 0.0,
    this.rewardPercentage = 0.1,
    DateTime? lastWeeklyAdjustmentDate,
  }) : lastActivityDate = lastActivityDate ?? DateTime(2000),
       lastWeeklyAdjustmentDate = lastWeeklyAdjustmentDate ?? DateTime(2000);

  User copyWith({
    int? id,
    String? name,
    double? pointBalance,
    int? streak,
    double? monthlyBudget,
    double? burnoutScore,
    double? adjustmentFactor,
    double? disciplineScore,
    double? xp,
    DateTime? lastActivityDate,
    bool? onboardingDone,
    double? income,
    double? rewardPercentage,
    DateTime? lastWeeklyAdjustmentDate,
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
      xp: xp ?? this.xp,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      income: income ?? this.income,
      rewardPercentage: rewardPercentage ?? this.rewardPercentage,
      lastWeeklyAdjustmentDate: lastWeeklyAdjustmentDate ?? this.lastWeeklyAdjustmentDate,
    );
  }
}
