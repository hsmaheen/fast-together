import 'package:fasting_app/domain/fasting_plan.dart';
import 'package:fasting_app/domain/fasting_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FastingSession', () {
    test('starts with a target end time derived from a Fasting Plan', () {
      final session = FastingSession.start(
        startTime: DateTime.utc(2026, 6, 20, 8),
        plan: FastingPlan.sixteenHours,
      );

      expect(session.targetEndTime, DateTime.utc(2026, 6, 21));
    });

    test('starts as an active Fasting Session', () {
      final session = FastingSession.start(
        startTime: DateTime.utc(2026, 6, 20, 8),
        plan: FastingPlan.sixteenHours,
      );

      expect(session.isActive, isTrue);
    });

    test('is active until an actual end time is set', () {
      final session = FastingSession(
        startTime: DateTime.utc(2026, 6, 20, 8),
        targetEndTime: DateTime.utc(2026, 6, 21),
      );

      expect(session.isActive, isTrue);
    });

    test('is not active after an actual end time is set', () {
      final session = FastingSession(
        startTime: DateTime.utc(2026, 6, 20, 8),
        targetEndTime: DateTime.utc(2026, 6, 21),
        actualEndTime: DateTime.utc(2026, 6, 21, 1),
      );

      expect(session.isActive, isFalse);
    });

    test('reports elapsed duration at a given time', () {
      final session = FastingSession(
        startTime: DateTime.utc(2026, 6, 20, 8),
        targetEndTime: DateTime.utc(2026, 6, 21),
      );

      expect(
        session.elapsedAt(DateTime.utc(2026, 6, 20, 13, 30)),
        const Duration(hours: 5, minutes: 30),
      );
    });

    test('reports remaining duration before the target end time', () {
      final session = FastingSession(
        startTime: DateTime.utc(2026, 6, 20, 8),
        targetEndTime: DateTime.utc(2026, 6, 21),
      );

      expect(
        session.remainingAt(DateTime.utc(2026, 6, 20, 20, 15)),
        const Duration(hours: 3, minutes: 45),
      );
    });

    test('reports over-target duration after the target end time', () {
      final session = FastingSession(
        startTime: DateTime.utc(2026, 6, 20, 8),
        targetEndTime: DateTime.utc(2026, 6, 21),
      );

      expect(
        session.overTargetAt(DateTime.utc(2026, 6, 21, 1, 20)),
        const Duration(hours: 1, minutes: 20),
      );
    });

    test('derives completed result when actual end reaches target end', () {
      final session = FastingSession(
        startTime: DateTime.utc(2026, 6, 20, 8),
        targetEndTime: DateTime.utc(2026, 6, 21),
        actualEndTime: DateTime.utc(2026, 6, 21, 0, 1),
      );

      expect(session.result, FastingResult.completed);
    });

    test('derives ended-early result when actual end is before target end', () {
      final session = FastingSession(
        startTime: DateTime.utc(2026, 6, 20, 8),
        targetEndTime: DateTime.utc(2026, 6, 21),
        actualEndTime: DateTime.utc(2026, 6, 20, 23, 59),
      );

      expect(session.result, FastingResult.endedEarly);
    });
  });
}
