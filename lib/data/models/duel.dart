import 'package:objectbox/objectbox.dart';

/// Status values for a Duel.
/// - 'active'      : duel sedang berlangsung
/// - 'user_won'    : user menang
/// - 'partner_won' : partner menang
/// - 'draw'        : seri
class DuelStatus {
  static const active = 'active';
  static const userWon = 'user_won';
  static const partnerWon = 'partner_won';
  static const draw = 'draw';
}

@Entity()
class Duel {
  @Id()
  int id;

  int partnerId;
  String partnerName;

  double myPoints;
  double partnerPoints;

  String status; // DuelStatus constants

  @Property(type: PropertyType.date)
  DateTime startAt;

  @Property(type: PropertyType.date)
  DateTime endAt;

  Duel({
    this.id = 0,
    required this.partnerId,
    required this.partnerName,
    this.myPoints = 0.0,
    this.partnerPoints = 0.0,
    this.status = DuelStatus.active,
    DateTime? startAt,
    DateTime? endAt,
  })  : startAt = startAt ?? DateTime.now(),
        endAt = endAt ?? DateTime.now().add(const Duration(days: 7));

  Duel copyWith({
    int? id,
    int? partnerId,
    String? partnerName,
    double? myPoints,
    double? partnerPoints,
    String? status,
    DateTime? startAt,
    DateTime? endAt,
  }) {
    return Duel(
      id: id ?? this.id,
      partnerId: partnerId ?? this.partnerId,
      partnerName: partnerName ?? this.partnerName,
      myPoints: myPoints ?? this.myPoints,
      partnerPoints: partnerPoints ?? this.partnerPoints,
      status: status ?? this.status,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
    );
  }

  bool get isActive => status == DuelStatus.active;
  bool get isExpired => DateTime.now().isAfter(endAt);
  int get daysRemaining => endAt.difference(DateTime.now()).inDays.clamp(0, 7);
}
