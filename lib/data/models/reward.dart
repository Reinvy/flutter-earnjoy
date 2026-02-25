import 'package:objectbox/objectbox.dart';

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

  Reward({
    this.id = 0,
    required this.name,
    required this.pointCost,
    this.progressPoints = 0.0,
    this.status = RewardStatus.locked,
  });

  bool get isLocked => !isRedeemed;
  bool get isUnlocked => !isRedeemed; // kept for compatibility; real check needs balance
  bool get isRedeemed => status == RewardStatus.redeemed;

  /// Whether the reward can be redeemed given the user's current [balance].
  bool canRedeemWithBalance(double balance) => !isRedeemed && balance >= pointCost;

  /// Progress fraction in [0.0, 1.0] based on user's current [balance].
  double progressFractionForBalance(double balance) =>
      pointCost > 0 ? (balance / pointCost).clamp(0.0, 1.0) : 0.0;

  Reward copyWith({
    int? id,
    String? name,
    double? pointCost,
    double? progressPoints,
    String? status,
  }) {
    return Reward(
      id: id ?? this.id,
      name: name ?? this.name,
      pointCost: pointCost ?? this.pointCost,
      progressPoints: progressPoints ?? this.progressPoints,
      status: status ?? this.status,
    );
  }
}
