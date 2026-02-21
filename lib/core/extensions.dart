extension DateTimeExtensions on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(yesterday);
  }

  String get formattedDate {
    return '$day/${month.toString().padLeft(2, '0')}/$year';
  }

  String get formattedTime {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}

extension IntExtensions on int {
  String get minutesToLabel {
    if (this < 60) return '${this}m';
    final h = this ~/ 60;
    final m = this % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  bool get isPositive => this > 0;
}

extension DoubleExtensions on double {
  /// Returns the number formatted with dot thousand-separators (Indonesian style).
  /// e.g. 1000000 → "1.000.000", 2500 → "2.500", 500 → "500"
  String get toPointsLabel {
    final n = round();
    if (n == 0) return '0';
    final isNegative = n < 0;
    final digits = n.abs().toString();
    final buffer = StringBuffer();
    final startLen = digits.length % 3;
    if (startLen > 0) buffer.write(digits.substring(0, startLen));
    for (int i = startLen; i < digits.length; i += 3) {
      if (buffer.isNotEmpty) buffer.write('.');
      buffer.write(digits.substring(i, i + 3));
    }
    return isNegative ? '-${buffer.toString()}' : buffer.toString();
  }
}
