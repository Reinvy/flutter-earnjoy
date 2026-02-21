import 'package:objectbox/objectbox.dart';

/// type constants
class TransactionType {
  static const earn = 'earn';
  static const redeem = 'redeem';
}

@Entity()
class Transaction {
  @Id()
  int id = 0;

  /// 'earn' | 'redeem'
  String type;

  double amount;
  @Property(type: PropertyType.date)
  DateTime date;

  /// Optional label (activity title or reward name)
  String label;

  Transaction({
    this.id = 0,
    required this.type,
    required this.amount,
    DateTime? date,
    this.label = '',
  }) : date = date ?? DateTime.now();

  bool get isEarn => type == TransactionType.earn;
  bool get isRedeem => type == TransactionType.redeem;

  Transaction copyWith({int? id, String? type, double? amount, DateTime? date, String? label}) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      label: label ?? this.label,
    );
  }
}
