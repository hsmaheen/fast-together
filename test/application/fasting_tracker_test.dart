import 'package:fasting_app/application/fasting_tracker.dart';
import 'package:fasting_app/domain/fasting_plan.dart';
import 'package:fasting_app/domain/fasting_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FastingTracker', () {
    FastingTracker trackerAfterTestSessions() {
      return FastingTracker(nowUtc: () => DateTime.utc(2026, 6, 23));
    }

    test('starts as Not Fasting', () {
      final tracker = FastingTracker();

      expect(tracker.status, FastingStatus.notFasting);
    });

    test('starts a current Fasting Session from a Fasting Plan', () {
      final tracker = trackerAfterTestSessions();
      final startTime = DateTime.utc(2026, 6, 21, 8);

      tracker.start(startTime: startTime, plan: FastingPlan.sixteenHours);

      expect(tracker.activeSession?.isActive, isTrue);
      expect(tracker.activeSession?.startTime, startTime);
      expect(tracker.activeSession?.targetEndTime, DateTime.utc(2026, 6, 22));
    });

    test('reports Fasting after starting', () {
      final tracker = trackerAfterTestSessions();

      tracker.start(
        startTime: DateTime.utc(2026, 6, 21, 8),
        plan: FastingPlan.sixteenHours,
      );

      expect(tracker.status, FastingStatus.fasting);
    });

    test('does not start while already Fasting', () {
      final tracker = trackerAfterTestSessions();
      tracker.start(
        startTime: DateTime.utc(2026, 6, 21, 8),
        plan: FastingPlan.sixteenHours,
      );

      expect(
        () => tracker.start(
          startTime: DateTime.utc(2026, 6, 21, 9),
          plan: FastingPlan.twelveHours,
        ),
        throwsStateError,
      );
    });

    test('does not start with a future start time', () {
      final tracker = FastingTracker(
        nowUtc: () => DateTime.utc(2026, 6, 21, 12),
      );

      expect(
        () => tracker.start(
          startTime: DateTime.utc(2026, 6, 21, 12, 1),
          plan: FastingPlan.sixteenHours,
        ),
        throwsArgumentError,
      );
    });

    test('ends the current Fasting Session', () {
      final tracker = trackerAfterTestSessions();
      tracker.start(
        startTime: DateTime.utc(2026, 6, 21, 8),
        plan: FastingPlan.sixteenHours,
      );
      final actualEndTime = DateTime.utc(2026, 6, 22, 1);

      tracker.end(actualEndTime: actualEndTime);

      expect(tracker.latestSession?.isActive, isFalse);
      expect(tracker.latestSession?.actualEndTime, actualEndTime);
    });

    test(
      'exposes active and latest Fasting Sessions separately after ending',
      () {
        final tracker = trackerAfterTestSessions();
        tracker.start(
          startTime: DateTime.utc(2026, 6, 21, 8),
          plan: FastingPlan.sixteenHours,
        );
        final actualEndTime = DateTime.utc(2026, 6, 22, 1);

        tracker.end(actualEndTime: actualEndTime);

        expect(tracker.activeSession, isNull);
        expect(tracker.latestSession?.actualEndTime, actualEndTime);
      },
    );

    test('reports Not Fasting after ending', () {
      final tracker = trackerAfterTestSessions();
      tracker.start(
        startTime: DateTime.utc(2026, 6, 21, 8),
        plan: FastingPlan.sixteenHours,
      );

      tracker.end(actualEndTime: DateTime.utc(2026, 6, 22, 1));

      expect(tracker.status, FastingStatus.notFasting);
    });

    test(
      'reports actual duration and result after ending a planned session',
      () {
        final tracker = trackerAfterTestSessions();
        tracker.start(
          startTime: DateTime.utc(2026, 6, 21, 8),
          plan: FastingPlan.sixteenHours,
        );

        tracker.end(actualEndTime: DateTime.utc(2026, 6, 22, 1, 30));

        expect(
          tracker.latestSession?.actualDuration,
          const Duration(hours: 17, minutes: 30),
        );
        expect(tracker.latestSession?.result, FastingResult.completed);
      },
    );

    test('corrects the latest ended Fasting Session actual end time', () {
      final tracker = trackerAfterTestSessions();
      tracker.start(
        startTime: DateTime.utc(2026, 6, 21, 8),
        plan: FastingPlan.sixteenHours,
      );
      tracker.end(actualEndTime: DateTime.utc(2026, 6, 22, 1, 30));

      tracker.correctActualEndTime(
        actualEndTime: DateTime.utc(2026, 6, 22, 0, 30),
      );

      expect(
        tracker.latestSession?.actualEndTime,
        DateTime.utc(2026, 6, 22, 0, 30),
      );
    });

    test('does not correct to a future actual end time', () {
      final tracker = FastingTracker(
        nowUtc: () => DateTime.utc(2026, 6, 22, 1),
      );
      tracker.start(
        startTime: DateTime.utc(2026, 6, 21, 8),
        plan: FastingPlan.sixteenHours,
      );
      tracker.end(actualEndTime: DateTime.utc(2026, 6, 22, 1));

      expect(
        () => tracker.correctActualEndTime(
          actualEndTime: DateTime.utc(2026, 6, 22, 1, 1),
        ),
        throwsArgumentError,
      );
    });

    test('does not end when Not Fasting', () {
      final tracker = FastingTracker();

      expect(
        () => tracker.end(actualEndTime: DateTime.utc(2026, 6, 22, 1)),
        throwsStateError,
      );
    });

    test('does not end with a future actual end time', () {
      final tracker = FastingTracker(
        nowUtc: () => DateTime.utc(2026, 6, 22, 1),
      );
      tracker.start(
        startTime: DateTime.utc(2026, 6, 21, 8),
        plan: FastingPlan.sixteenHours,
      );

      expect(
        () => tracker.end(actualEndTime: DateTime.utc(2026, 6, 22, 1, 1)),
        throwsArgumentError,
      );
    });
  });
}
