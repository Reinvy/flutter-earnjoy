/// Represents a single historical streak period.
/// Plain Dart class — not stored in ObjectBox (computed on-the-fly from Activity data).
class StreakRecord {
  final int days;
  final DateTime startDate;
  final DateTime endDate;

  /// True when this streak started after a break of ≥ 7 days.
  final bool isComeback;

  const StreakRecord({
    required this.days,
    required this.startDate,
    required this.endDate,
    this.isComeback = false,
  });
}
