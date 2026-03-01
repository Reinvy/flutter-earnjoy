import 'package:objectbox/objectbox.dart';

/// Reward category constants
class RewardCategory {
  static const food = 'food';
  static const entertainment = 'entertainment';
  static const shopping = 'shopping';
  static const experience = 'experience';
  static const selfGrowth = 'self_growth';
  static const rest = 'rest';

  static const all = [food, entertainment, shopping, experience, selfGrowth, rest];

  static String label(String key) => switch (key) {
        food => 'Food & Drink',
        entertainment => 'Entertainment',
        shopping => 'Shopping',
        experience => 'Experience',
        selfGrowth => 'Self-Growth',
        rest => 'Rest',
        _ => 'Other',
      };

  static String emoji(String key) => switch (key) {
        food => '🍔',
        entertainment => '🎮',
        shopping => '🛍️',
        experience => '✈️',
        selfGrowth => '📚',
        rest => '💤',
        _ => '🎁',
      };
}

/// Recurrence type constants
class RecurrenceType {
  static const once = 'once';
  static const recurring = 'recurring';
  static const limited = 'limited';
}

/// status constants - only 'locked' (default) and 'redeemed' are meaningful now.
/// 'unlocked' is derived at runtime from pointBalance >= pointCost.
class RewardStatus {
  static const locked = 'locked';
  static const unlocked = 'unlocked';
  static const redeemed = 'redeemed';
}

@Entity()
class Reward {
  @Id()
  int id = 0;

  String name;
  double pointCost;

  // Kept for ObjectBox schema compatibility - no longer written or read for
  // progress display. Progress is now computed from user.pointBalance.
  double progressPoints;

  /// 'locked' | 'redeemed'
  /// ('unlocked' is never stored; unlock = balance >= pointCost, computed live)
  String status;

  // ─── New fields for Feature 8 ───────────────────────────────────────────

  /// Reward category: 'food' | 'entertainment' | 'shopping' | 'experience' | 'self_growth' | 'rest'
  String category;

  /// Emoji icon for display — e.g. '🍜', '☕', '🎬'
  String iconEmoji;

  /// Recurrence: 'once' | 'recurring' | 'limited'
  String recurrenceType;

  /// For 'recurring' type — interval in days before it can be redeemed again
  int? recurrenceIntervalDays;

  /// For 'limited' type — max times redeemable per calendar month
  int? monthlyLimit;

  /// How many times this reward has been redeemed (used for limited tracking)
  int timesRedeemed;

  /// ISO8601 string of the last redeem date (for recurring cooldown check)
  String? lastRedeemedAt;

  /// Optional scheduled date for the redeem — shown as countdown in card
  @Property(type: PropertyType.date)
  DateTime? scheduledFor;

  /// Whether this is a built-in template (shown in Shop tab)
  bool isTemplate;

  /// Whether user has archived this reward (hidden from active list)
  bool isArchived;

  Reward({
    this.id = 0,
    required this.name,
    required this.pointCost,
    this.progressPoints = 0.0,
    this.status = RewardStatus.locked,
    this.category = RewardCategory.food,
    this.iconEmoji = '🎁',
    this.recurrenceType = RecurrenceType.once,
    this.recurrenceIntervalDays,
    this.monthlyLimit,
    this.timesRedeemed = 0,
    this.lastRedeemedAt,
    this.scheduledFor,
    this.isTemplate = false,
    this.isArchived = false,
  });

  bool get isLocked => !isRedeemed;
  bool get isUnlocked => !isRedeemed; // kept for compatibility; real check needs balance
  bool get isRedeemed => status == RewardStatus.redeemed;

  /// Whether the reward can be redeemed given the user's current [balance].
  bool canRedeemWithBalance(double balance) => !isRedeemed && balance >= pointCost;

  /// Progress fraction in [0.0, 1.0] based on user's current [balance].
  double progressFractionForBalance(double balance) =>
      pointCost > 0 ? (balance / pointCost).clamp(0.0, 1.0) : 0.0;

  /// Whether a recurring reward has cooled down and can be redeemed again.
  bool get isRecurringReady {
    if (recurrenceType != RecurrenceType.recurring) return false;
    if (lastRedeemedAt == null) return true;
    final last = DateTime.tryParse(lastRedeemedAt!);
    if (last == null) return true;
    final interval = recurrenceIntervalDays ?? 7;
    return DateTime.now().difference(last).inDays >= interval;
  }

  /// How many days until a recurring reward is available again.
  int get recurringCooldownDaysLeft {
    if (lastRedeemedAt == null) return 0;
    final last = DateTime.tryParse(lastRedeemedAt!);
    if (last == null) return 0;
    final interval = recurrenceIntervalDays ?? 7;
    final elapsed = DateTime.now().difference(last).inDays;
    return (interval - elapsed).clamp(0, interval);
  }

  /// How many days until the scheduled redeem date.
  int? get scheduledDaysLeft {
    if (scheduledFor == null) return null;
    final diff = scheduledFor!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  Reward copyWith({
    int? id,
    String? name,
    double? pointCost,
    double? progressPoints,
    String? status,
    String? category,
    String? iconEmoji,
    String? recurrenceType,
    int? recurrenceIntervalDays,
    int? monthlyLimit,
    int? timesRedeemed,
    String? lastRedeemedAt,
    DateTime? scheduledFor,
    bool? isTemplate,
    bool? isArchived,
    bool clearScheduledFor = false,
    bool clearLastRedeemedAt = false,
  }) {
    return Reward(
      id: id ?? this.id,
      name: name ?? this.name,
      pointCost: pointCost ?? this.pointCost,
      progressPoints: progressPoints ?? this.progressPoints,
      status: status ?? this.status,
      category: category ?? this.category,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceIntervalDays: recurrenceIntervalDays ?? this.recurrenceIntervalDays,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      timesRedeemed: timesRedeemed ?? this.timesRedeemed,
      lastRedeemedAt: clearLastRedeemedAt ? null : (lastRedeemedAt ?? this.lastRedeemedAt),
      scheduledFor: clearScheduledFor ? null : (scheduledFor ?? this.scheduledFor),
      isTemplate: isTemplate ?? this.isTemplate,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
