import 'package:fasting_app/domain/fasting_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FastingPlan', () {
    test('exposes durations for the MVP preset plans', () {
      expect(FastingPlan.tenHours.duration, const Duration(hours: 10));
      expect(FastingPlan.twelveHours.duration, const Duration(hours: 12));
      expect(FastingPlan.fourteenHours.duration, const Duration(hours: 14));
      expect(FastingPlan.sixteenHours.duration, const Duration(hours: 16));
      expect(FastingPlan.eighteenHours.duration, const Duration(hours: 18));
      expect(FastingPlan.twentyFourHours.duration, const Duration(hours: 24));
      expect(FastingPlan.fortyEightHours.duration, const Duration(hours: 48));
    });

    test('accepts custom whole-hour durations from 1 to 168', () {
      expect(FastingPlan.customHours(1).duration, const Duration(hours: 1));
      expect(FastingPlan.customHours(20).duration, const Duration(hours: 20));
      expect(FastingPlan.customHours(168).duration, const Duration(hours: 168));
    });

    test('rejects a custom duration below one hour', () {
      expect(() => FastingPlan.customHours(-1), throwsArgumentError);
      expect(() => FastingPlan.customHours(0), throwsArgumentError);
    });

    test('rejects a custom duration above 168 hours', () {
      expect(() => FastingPlan.customHours(169), throwsArgumentError);
    });

    test('calculates target end time from a start time', () {
      final startTime = DateTime.utc(2026, 6, 20, 8, 30);

      expect(
        FastingPlan.sixteenHours.targetEndTimeFrom(startTime),
        DateTime.utc(2026, 6, 21, 0, 30),
      );
    });

    test('rejects a non-UTC start time when deriving target end time', () {
      final localStartTime = DateTime(2026, 6, 20, 8, 30);

      expect(
        () => FastingPlan.sixteenHours.targetEndTimeFrom(localStartTime),
        throwsArgumentError,
      );
    });
  });
}
