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

    test('does not start from a non-UTC start time', () {
      expect(
        () => FastingSession.start(
          startTime: DateTime(2026, 6, 20, 8),
          plan: FastingPlan.sixteenHours,
        ),
        throwsArgumentError,
      );
    });

    test('is active until an actual end time is set', () {
      final session = activeSession();

      expect(session.isActive, isTrue);
    });

    test('has no actual duration while active', () {
      final session = activeSession();

      expect(session.actualDuration, isNull);
    });

    test('ends with a supplied actual end time', () {
      final session = activeSession();
      final actualEndTime = DateTime.utc(2026, 6, 21, 1);

      final endedSession = session.end(actualEndTime: actualEndTime);

      expect(endedSession.actualEndTime, actualEndTime);
    });

    test('is not active after ending', () {
      final session = activeSession();

      final endedSession = session.end(
        actualEndTime: DateTime.utc(2026, 6, 21, 1),
      );

      expect(endedSession.isActive, isFalse);
    });

    test('reports actual duration after ending', () {
      final session = activeSession();

      final endedSession = session.end(
        actualEndTime: DateTime.utc(2026, 6, 21, 1),
      );

      expect(endedSession.actualDuration, const Duration(hours: 17));
    });

    test('preserves minute precision for actual duration', () {
      final session = activeSession();

      final endedSession = session.end(
        actualEndTime: DateTime.utc(2026, 6, 21, 4, 1),
      );

      expect(
        endedSession.actualDuration,
        const Duration(hours: 20, minutes: 1),
      );
    });

    test('corrects actual end time after ending', () {
      final endedSession = endedSessionAfterTarget();
      final correctedEndTime = DateTime.utc(2026, 6, 21, 0, 30);

      final correctedSession = endedSession.correctActualEndTime(
        actualEndTime: correctedEndTime,
      );

      expect(correctedSession.actualEndTime, correctedEndTime);
    });

    test('recalculates actual duration after correcting actual end time', () {
      final endedSession = endedSessionAfterTarget();

      final correctedSession = endedSession.correctActualEndTime(
        actualEndTime: DateTime.utc(2026, 6, 20, 20, 30),
      );

      expect(
        correctedSession.actualDuration,
        const Duration(hours: 12, minutes: 30),
      );
    });

    test('recalculates result after correcting actual end time', () {
      final endedSession = endedSessionAfterTarget();

      final correctedSession = endedSession.correctActualEndTime(
        actualEndTime: DateTime.utc(2026, 6, 20, 23, 30),
      );

      expect(correctedSession.result, FastingResult.endedEarly);
    });

    test('does not correct to a non-UTC actual end time', () {
      final endedSession = endedSessionAfterTarget();

      expect(
        () => endedSession.correctActualEndTime(
          actualEndTime: DateTime(2026, 6, 21),
        ),
        throwsArgumentError,
      );
    });

    test('does not correct actual end time to the start time', () {
      final startTime = DateTime.utc(2026, 6, 20, 8);
      final endedSession = endedSessionAfterTarget(startTime: startTime);

      expect(
        () => endedSession.correctActualEndTime(actualEndTime: startTime),
        throwsArgumentError,
      );
    });

    test('does not correct actual end time before the start time', () {
      final endedSession = endedSessionAfterTarget();

      expect(
        () => endedSession.correctActualEndTime(
          actualEndTime: DateTime.utc(2026, 6, 20, 7, 59),
        ),
        throwsArgumentError,
      );
    });

    test('does not correct actual end time while active', () {
      final session = activeSession();

      expect(
        () => session.correctActualEndTime(
          actualEndTime: DateTime.utc(2026, 6, 21, 1),
        ),
        throwsStateError,
      );
    });

    test('ends as completed when actual end reaches target end', () {
      final session = activeSession();

      final endedSession = session.end(
        actualEndTime: DateTime.utc(2026, 6, 21),
      );

      expect(endedSession.result, FastingResult.completed);
    });

    test('ends early when actual end is before target end', () {
      final session = activeSession();

      final endedSession = session.end(
        actualEndTime: DateTime.utc(2026, 6, 20, 23),
      );

      expect(endedSession.result, FastingResult.endedEarly);
    });

    test('does not end with a non-UTC actual end time', () {
      final session = activeSession();

      expect(
        () => session.end(actualEndTime: DateTime(2026, 6, 21, 1)),
        throwsArgumentError,
      );
    });

    test('does not end at the start time', () {
      final startTime = DateTime.utc(2026, 6, 20, 8);
      final session = activeSession(startTime: startTime);

      expect(() => session.end(actualEndTime: startTime), throwsArgumentError);
    });

    test('does not end before the start time', () {
      final session = activeSession();

      expect(
        () => session.end(actualEndTime: DateTime.utc(2026, 6, 20, 7, 59)),
        throwsArgumentError,
      );
    });

    test('does not end an already ended Fasting Session', () {
      final endedSession = endedSessionAfterTarget();

      expect(
        () => endedSession.end(actualEndTime: DateTime.utc(2026, 6, 21, 2)),
        throwsStateError,
      );
    });

    test('rejects a non-UTC start time', () {
      expect(
        () => FastingSession(
          startTime: DateTime(2026, 6, 20, 8),
          targetEndTime: DateTime.utc(2026, 6, 21),
        ),
        throwsArgumentError,
      );
    });

    test('rejects a non-UTC target end time', () {
      expect(
        () => FastingSession(
          startTime: DateTime.utc(2026, 6, 20, 8),
          targetEndTime: DateTime(2026, 6, 21),
        ),
        throwsArgumentError,
      );
    });

    test('rejects a target end time equal to the start time', () {
      final startTime = DateTime.utc(2026, 6, 20, 8);

      expect(
        () => FastingSession(startTime: startTime, targetEndTime: startTime),
        throwsArgumentError,
      );
    });

    test('rejects a target end time before the start time', () {
      expect(
        () => FastingSession(
          startTime: DateTime.utc(2026, 6, 20, 8),
          targetEndTime: DateTime.utc(2026, 6, 20, 7, 59),
        ),
        throwsArgumentError,
      );
    });

    test('is not active after an actual end time is set', () {
      final session = endedSessionAfterTarget();

      expect(session.isActive, isFalse);
    });

    test('rejects a non-UTC actual end time', () {
      expect(
        () => FastingSession(
          startTime: DateTime.utc(2026, 6, 20, 8),
          targetEndTime: DateTime.utc(2026, 6, 21),
          actualEndTime: DateTime(2026, 6, 21, 1),
        ),
        throwsArgumentError,
      );
    });

    test('reports elapsed duration at a given time', () {
      final session = activeSession();

      expect(
        session.elapsedAt(DateTime.utc(2026, 6, 20, 13, 30)),
        const Duration(hours: 5, minutes: 30),
      );
    });

    test('does not report elapsed duration for a non-UTC time', () {
      final session = activeSession();

      expect(
        () => session.elapsedAt(DateTime(2026, 6, 20, 13, 30)),
        throwsArgumentError,
      );
    });

    test('reports remaining duration before the target end time', () {
      final session = activeSession();

      expect(
        session.remainingAt(DateTime.utc(2026, 6, 20, 20, 15)),
        const Duration(hours: 3, minutes: 45),
      );
    });

    test('does not report remaining duration for a non-UTC time', () {
      final session = activeSession();

      expect(
        () => session.remainingAt(DateTime(2026, 6, 20, 20, 15)),
        throwsArgumentError,
      );
    });

    test('reports over-target duration after the target end time', () {
      final session = activeSession();

      expect(
        session.overTargetAt(DateTime.utc(2026, 6, 21, 1, 20)),
        const Duration(hours: 1, minutes: 20),
      );
    });

    test('does not report over-target duration for a non-UTC time', () {
      final session = activeSession();

      expect(
        () => session.overTargetAt(DateTime(2026, 6, 21, 1, 20)),
        throwsArgumentError,
      );
    });

    test('derives completed result when actual end reaches target end', () {
      final session = endedSessionAfterTarget(
        actualEndTime: DateTime.utc(2026, 6, 21, 0, 1),
      );

      expect(session.result, FastingResult.completed);
    });

    test('derives ended-early result when actual end is before target end', () {
      final session = endedSessionBeforeTarget(
        actualEndTime: DateTime.utc(2026, 6, 20, 23, 59),
      );

      expect(session.result, FastingResult.endedEarly);
    });
  });
}

FastingSession activeSession({DateTime? startTime, DateTime? targetEndTime}) {
  final resolvedStartTime = startTime ?? DateTime.utc(2026, 6, 20, 8);

  return FastingSession(
    startTime: resolvedStartTime,
    targetEndTime:
        targetEndTime ?? resolvedStartTime.add(const Duration(hours: 16)),
  );
}

FastingSession endedSessionAfterTarget({
  DateTime? startTime,
  DateTime? targetEndTime,
  DateTime? actualEndTime,
}) {
  final session = activeSession(
    startTime: startTime,
    targetEndTime: targetEndTime,
  );

  return FastingSession(
    startTime: session.startTime,
    targetEndTime: session.targetEndTime,
    actualEndTime:
        actualEndTime ?? session.targetEndTime.add(const Duration(hours: 1)),
  );
}

FastingSession endedSessionBeforeTarget({
  DateTime? startTime,
  DateTime? targetEndTime,
  DateTime? actualEndTime,
}) {
  final session = activeSession(
    startTime: startTime,
    targetEndTime: targetEndTime,
  );

  return FastingSession(
    startTime: session.startTime,
    targetEndTime: session.targetEndTime,
    actualEndTime:
        actualEndTime ??
        session.targetEndTime.subtract(const Duration(hours: 1)),
  );
}
