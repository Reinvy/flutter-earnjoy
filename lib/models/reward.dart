import 'package:objectbox/objectbox.dart';

/// status constants
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
  double progressPoints;

  /// 'locked' | 'unlocked' | 'redeemed'
  String status;

  Reward({
    this.id = 0,
    required this.name,
    required this.pointCost,
    this.progressPoints = 0.0,
    this.status = RewardStatus.locked,
  });

  bool get isLocked => status == RewardStatus.locked;
  bool get isUnlocked => status == RewardStatus.unlocked;
  bool get isRedeemed => status == RewardStatus.redeemed;

  double get progressFraction =>
      (pointCost > 0) ? (progressPoints / pointCost).clamp(0.0, 1.0) : 0.0;

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
