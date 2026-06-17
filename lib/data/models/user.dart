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

  // Insights / analytics
  double dailyPointTarget;

  // Onboarding fields
  bool onboardingDone;
  double income;
  double rewardPercentage;

  // Weekly difficulty adjustment tracking
  @Property(type: PropertyType.date)
  DateTime lastWeeklyAdjustmentDate;

  // Smart notification preferences
  bool notificationsEnabled;
  int preferredReminderHour; // -1 = auto (derived from activity patterns)
  int quietHoursStart;       // hour 0-23, default 22 (22:00)
  int quietHoursEnd;         // hour 0-23, default 7  (07:00)

  // Anti-Burnout & Rest Day tracking
  int restDayCount;           // Total rest days declared ever
  @Property(type: PropertyType.date)
  DateTime lastRestDayDate;   // Date of last rest day (for 7-day cooldown)

  // Social & Accountability (Feature 12)
  bool socialEnabled;         // opt-in privacy gate; default false
  String inviteCode;          // 8-char unique code generated on enable

  // Onboarding personalization (Feature 11)
  String selectedGoalsJson;   // JSON list, e.g. '["Work","Health"]'
  String dreamReward;         // Name of first dream reward
  String dreamRewardEmoji;    // Emoji for the dream reward category
  int preferredActiveHour;    // User's most active hour: 6,10,14, or 18 (-1 = unset)

  // Cloud Sync
  String? cloudId;            // UUID from Supabase (null = not yet synced)
  @Property(type: PropertyType.date)
  DateTime updatedAt;         // For last-write-wins conflict resolution

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
    this.dailyPointTarget = 300.0,
    this.onboardingDone = false,
    this.income = 0.0,
    this.rewardPercentage = 0.1,
    DateTime? lastWeeklyAdjustmentDate,
    this.notificationsEnabled = true,
    this.preferredReminderHour = -1,
    this.quietHoursStart = 22,
    this.quietHoursEnd = 7,
    this.restDayCount = 0,
    DateTime? lastRestDayDate,
    this.selectedGoalsJson = '[]',
    this.dreamReward = '',
    this.dreamRewardEmoji = '🎁',
    this.preferredActiveHour = -1,
    this.socialEnabled = false,
    this.inviteCode = '',
    this.cloudId,
    DateTime? updatedAt,
  }) : lastActivityDate = lastActivityDate ?? DateTime(2000),
       lastWeeklyAdjustmentDate = lastWeeklyAdjustmentDate ?? DateTime(2000),
       lastRestDayDate = lastRestDayDate ?? DateTime(2000),
       updatedAt = updatedAt ?? DateTime.now();

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
    double? dailyPointTarget,
    bool? onboardingDone,
    double? income,
    double? rewardPercentage,
    DateTime? lastWeeklyAdjustmentDate,
    bool? notificationsEnabled,
    int? preferredReminderHour,
    int? quietHoursStart,
    int? quietHoursEnd,
    int? restDayCount,
    DateTime? lastRestDayDate,
    String? selectedGoalsJson,
    String? dreamReward,
    String? dreamRewardEmoji,
    int? preferredActiveHour,
    bool? socialEnabled,
    String? inviteCode,
    String? cloudId,
    bool clearCloudId = false,
    DateTime? updatedAt,
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
      dailyPointTarget: dailyPointTarget ?? this.dailyPointTarget,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      income: income ?? this.income,
      rewardPercentage: rewardPercentage ?? this.rewardPercentage,
      lastWeeklyAdjustmentDate: lastWeeklyAdjustmentDate ?? this.lastWeeklyAdjustmentDate,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      preferredReminderHour: preferredReminderHour ?? this.preferredReminderHour,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      restDayCount: restDayCount ?? this.restDayCount,
      lastRestDayDate: lastRestDayDate ?? this.lastRestDayDate,
      selectedGoalsJson: selectedGoalsJson ?? this.selectedGoalsJson,
      dreamReward: dreamReward ?? this.dreamReward,
      dreamRewardEmoji: dreamRewardEmoji ?? this.dreamRewardEmoji,
      preferredActiveHour: preferredActiveHour ?? this.preferredActiveHour,
      socialEnabled: socialEnabled ?? this.socialEnabled,
      inviteCode: inviteCode ?? this.inviteCode,
      cloudId: clearCloudId ? null : (cloudId ?? this.cloudId),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
