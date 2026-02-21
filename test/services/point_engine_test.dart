import 'package:flutter_test/flutter_test.dart';
import 'package:earnjoy/services/point_engine.dart';
import 'package:earnjoy/core/constants.dart';

void main() {
  group('PointEngine.calculateStreakBonus', () {
    test('no streak → bonus is 1.0', () {
      expect(PointEngine.calculateStreakBonus(0), equals(1.0));
    });

    test('1-day streak → 1.05', () {
      expect(PointEngine.calculateStreakBonus(1), closeTo(1.05, 0.001));
    });

    test('10-day streak → 1.5', () {
      expect(PointEngine.calculateStreakBonus(10), closeTo(1.5, 0.001));
    });

    test('20-day streak → 2.0', () {
      expect(PointEngine.calculateStreakBonus(20), closeTo(2.0, 0.001));
    });
  });

  group('PointEngine.calculatePoints', () {
    test('Study 30m, no streak, no adjustment → 30 * 1.2 * 1.0 * 1.0 = 36', () {
      final pts = PointEngine.calculatePoints(
        category: 'Study',
        durationMinutes: 30,
        streakDays: 0,
        adjustmentFactor: 1.0,
      );
      expect(pts, closeTo(36.0, 0.001));
    });

    test('Work 60m, no streak → 60 * 1.3 = 78', () {
      final pts = PointEngine.calculatePoints(category: 'Work', durationMinutes: 60, streakDays: 0);
      expect(pts, closeTo(78.0, 0.001));
    });

    test('Health 45m, no streak → 45 * 1.1 = 49.5', () {
      final pts = PointEngine.calculatePoints(
        category: 'Health',
        durationMinutes: 45,
        streakDays: 0,
      );
      expect(pts, closeTo(49.5, 0.001));
    });

    test('Fun 60m, no streak → 60 * 0.5 = 30', () {
      final pts = PointEngine.calculatePoints(category: 'Fun', durationMinutes: 60, streakDays: 0);
      expect(pts, closeTo(30.0, 0.001));
    });

    test('Unknown category falls back to weight 1.0', () {
      final pts = PointEngine.calculatePoints(
        category: 'UnknownCategory',
        durationMinutes: 100,
        streakDays: 0,
      );
      expect(pts, closeTo(100.0, 0.001));
    });

    test('Streak bonus multiplied correctly', () {
      // Study 30m, 10-day streak (bonus=1.5) → 30 * 1.2 * 1.5 = 54
      final pts = PointEngine.calculatePoints(
        category: 'Study',
        durationMinutes: 30,
        streakDays: 10,
      );
      expect(pts, closeTo(54.0, 0.001));
    });

    test('Adjustment factor scales linearly', () {
      final base = PointEngine.calculatePoints(
        category: 'Study',
        durationMinutes: 30,
        streakDays: 0,
        adjustmentFactor: 1.0,
      );
      final adjusted = PointEngine.calculatePoints(
        category: 'Study',
        durationMinutes: 30,
        streakDays: 0,
        adjustmentFactor: 0.5,
      );
      expect(adjusted, closeTo(base * 0.5, 0.001));
    });
  });

  group('PointEngine.applyDiminishingReturn', () {
    test('First activity (count=0) → no reduction', () {
      expect(PointEngine.applyDiminishingReturn(100.0, 0), equals(100.0));
    });

    test('Second activity (count=1) → reduced by factor', () {
      final result = PointEngine.applyDiminishingReturn(100.0, 1);
      expect(result, closeTo(100.0 * diminishingReturnFactor, 0.001));
    });

    test('Third activity (count=2) → reduced by factor^2', () {
      final expected = 100.0 * diminishingReturnFactor * diminishingReturnFactor;
      expect(PointEngine.applyDiminishingReturn(100.0, 2), closeTo(expected, 0.001));
    });

    test('Points decrease monotonically with higher counts', () {
      final p0 = PointEngine.applyDiminishingReturn(100.0, 0);
      final p1 = PointEngine.applyDiminishingReturn(100.0, 1);
      final p2 = PointEngine.applyDiminishingReturn(100.0, 2);
      expect(p0 > p1, isTrue);
      expect(p1 > p2, isTrue);
    });
  });

  group('PointEngine.isOverDailyLimit', () {
    test('below cap → false', () {
      expect(PointEngine.isOverDailyLimit(maxPointsPerDay - 1), isFalse);
    });

    test('exactly at cap → true', () {
      expect(PointEngine.isOverDailyLimit(maxPointsPerDay), isTrue);
    });

    test('above cap → true', () {
      expect(PointEngine.isOverDailyLimit(maxPointsPerDay + 100), isTrue);
    });

    test('zero → false', () {
      expect(PointEngine.isOverDailyLimit(0), isFalse);
    });
  });

  group('PointEngine.clampToDailyCap', () {
    test('points within remaining capacity → unchanged', () {
      expect(PointEngine.clampToDailyCap(50.0, 0.0), equals(50.0));
    });

    test('points exceed remaining capacity → clamped', () {
      final current = maxPointsPerDay - 10;
      expect(PointEngine.clampToDailyCap(50.0, current), closeTo(10.0, 0.001));
    });

    test('already at cap → 0 points earned', () {
      expect(PointEngine.clampToDailyCap(100.0, maxPointsPerDay), equals(0.0));
    });
  });
}
