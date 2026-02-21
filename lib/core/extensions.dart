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
  String get toPointsLabel {
    if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed(1)}k';
    }
    return toStringAsFixed(0);
  }
}
