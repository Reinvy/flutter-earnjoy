import 'package:objectbox/objectbox.dart';

@Entity()
class AccountabilityPartner {
  @Id()
  int id;

  String name;
  String inviteCode;
  double weeklyPoints;
  int streakDays;
  bool isPrivacyShared; // partner setuju share stats

  @Property(type: PropertyType.date)
  DateTime joinedAt;

  AccountabilityPartner({
    this.id = 0,
    required this.name,
    required this.inviteCode,
    this.weeklyPoints = 0.0,
    this.streakDays = 0,
    this.isPrivacyShared = true,
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();

  AccountabilityPartner copyWith({
    int? id,
    String? name,
    String? inviteCode,
    double? weeklyPoints,
    int? streakDays,
    bool? isPrivacyShared,
    DateTime? joinedAt,
  }) {
    return AccountabilityPartner(
      id: id ?? this.id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      weeklyPoints: weeklyPoints ?? this.weeklyPoints,
      streakDays: streakDays ?? this.streakDays,
      isPrivacyShared: isPrivacyShared ?? this.isPrivacyShared,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}
