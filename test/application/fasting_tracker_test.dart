import 'package:fasting_app/application/fasting_tracker.dart';
import 'package:fasting_app/domain/fasting_plan.dart';
import 'package:fasting_app/domain/fasting_session.dart';
import 'package:fasting_app/domain/fasting_session_id.dart';
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

    test('exposes recent ended Fasting Sessions newest-first', () {
      final tracker = trackerAfterTestSessions();
      tracker.start(
        startTime: DateTime.utc(2026, 6, 20, 8),
        plan: FastingPlan.sixteenHours,
      );
      final olderEndTime = DateTime.utc(2026, 6, 21, 1);
      tracker.end(actualEndTime: olderEndTime);
      tracker.start(
        startTime: DateTime.utc(2026, 6, 21, 8),
        plan: FastingPlan.sixteenHours,
      );
      final newerEndTime = DateTime.utc(2026, 6, 22, 1);

      tracker.end(actualEndTime: newerEndTime);

      expect(
        tracker.recentEndedSessions.map((session) => session.actualEndTime),
        [newerEndTime, olderEndTime],
      );
    });

    test(
      'keeps Personal Fasting Activity newest-first after ending backdated sessions',
      () {
        final ids = [
          FastingSessionId('z-newest'),
          FastingSessionId('b-tied'),
          FastingSessionId('a-tied'),
        ];
        final tracker = FastingTracker(
          nowUtc: () => DateTime.utc(2026, 6, 23),
          newSessionId: () => ids.removeAt(0),
        );
        tracker.start(
          startTime: DateTime.utc(2026, 6, 20, 8),
          plan: FastingPlan.sixteenHours,
        );
        tracker.end(actualEndTime: DateTime.utc(2026, 6, 22, 1));
        tracker.start(
          startTime: DateTime.utc(2026, 6, 19, 8),
          plan: FastingPlan.sixteenHours,
        );
        tracker.end(actualEndTime: DateTime.utc(2026, 6, 21, 1));
        tracker.start(
          startTime: DateTime.utc(2026, 6, 20, 8),
          plan: FastingPlan.sixteenHours,
        );
        tracker.end(actualEndTime: DateTime.utc(2026, 6, 21, 1));

        expect(tracker.recentEndedSessions.map((session) => session.id.value), [
          'z-newest',
          'a-tied',
          'b-tied',
        ]);
        expect(tracker.latestSession?.id.value, 'z-newest');
      },
    );

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

    test('totals ended Fasting Sessions for the same local date', () {
      final tracker = trackerAfterTestSessions();
      tracker.start(
        startTime: DateTime.utc(2026, 6, 20, 8),
        plan: FastingPlan.sixteenHours,
      );
      tracker.end(actualEndTime: DateTime.utc(2026, 6, 21, 0));
      tracker.start(
        startTime: DateTime.utc(2026, 6, 21, 8),
        plan: FastingPlan.twelveHours,
      );
      tracker.end(actualEndTime: DateTime.utc(2026, 6, 21, 15, 30));

      expect(
        tracker.dailyFastingTotals(
          localTimeFor: (time) => time.add(const Duration(hours: 8)),
        ),
        [
          DailyFastingTotal(
            date: DateTime(2026, 6, 21),
            duration: const Duration(hours: 23, minutes: 30),
          ),
        ],
      );
    });

    test('keeps daily fasting totals on separate local dates', () {
      final tracker = trackerAfterTestSessions();
      tracker.start(
        startTime: DateTime.utc(2026, 6, 19, 8),
        plan: FastingPlan.sixteenHours,
      );
      tracker.end(actualEndTime: DateTime.utc(2026, 6, 20, 0));
      tracker.start(
        startTime: DateTime.utc(2026, 6, 21, 8),
        plan: FastingPlan.twelveHours,
      );
      tracker.end(actualEndTime: DateTime.utc(2026, 6, 21, 20));

      expect(
        tracker.dailyFastingTotals(
          localTimeFor: (time) => time.add(const Duration(hours: 8)),
        ),
        [
          DailyFastingTotal(
            date: DateTime(2026, 6, 22),
            duration: const Duration(hours: 12),
          ),
          DailyFastingTotal(
            date: DateTime(2026, 6, 20),
            duration: const Duration(hours: 16),
          ),
        ],
      );
    });

    test('does not count an active Fasting Session in daily totals', () {
      final tracker = trackerAfterTestSessions();
      tracker.start(
        startTime: DateTime.utc(2026, 6, 20, 8),
        plan: FastingPlan.sixteenHours,
      );
      tracker.end(actualEndTime: DateTime.utc(2026, 6, 21, 0));
      tracker.start(
        startTime: DateTime.utc(2026, 6, 21, 8),
        plan: FastingPlan.twelveHours,
      );

      expect(
        tracker.dailyFastingTotals(
          localTimeFor: (time) => time.add(const Duration(hours: 8)),
        ),
        [
          DailyFastingTotal(
            date: DateTime(2026, 6, 21),
            duration: const Duration(hours: 16),
          ),
        ],
      );
    });

    test('deletes the latest ended Fasting Session', () {
      final tracker = trackerAfterTestSessions();
      tracker.start(
        startTime: DateTime.utc(2026, 6, 21, 8),
        plan: FastingPlan.sixteenHours,
      );
      tracker.end(actualEndTime: DateTime.utc(2026, 6, 22, 1));

      tracker.deleteLatestEndedSession();

      expect(tracker.latestSession, isNull);
      expect(tracker.activeSession, isNull);
      expect(tracker.status, FastingStatus.notFasting);
    });

    test('deleting the latest ended Fasting Session keeps older history', () {
      final tracker = trackerAfterTestSessions();
      tracker.start(
        startTime: DateTime.utc(2026, 6, 20, 8),
        plan: FastingPlan.sixteenHours,
      );
      final olderEndTime = DateTime.utc(2026, 6, 21, 1);
      tracker.end(actualEndTime: olderEndTime);
      tracker.start(
        startTime: DateTime.utc(2026, 6, 21, 8),
        plan: FastingPlan.sixteenHours,
      );
      tracker.end(actualEndTime: DateTime.utc(2026, 6, 22, 1));

      tracker.deleteLatestEndedSession();

      expect(tracker.latestSession?.actualEndTime, olderEndTime);
      expect(
        tracker.recentEndedSessions.map((session) => session.actualEndTime),
        [olderEndTime],
      );
    });

    test(
      'deletes a specific ended Fasting Session by ID from recent history',
      () {
        final tracker = trackerAfterTestSessions();
        tracker.start(
          startTime: DateTime.utc(2026, 6, 19, 8),
          plan: FastingPlan.sixteenHours,
        );
        final oldestEndTime = DateTime.utc(2026, 6, 20, 1);
        tracker.end(actualEndTime: oldestEndTime);
        tracker.start(
          startTime: DateTime.utc(2026, 6, 20, 8),
          plan: FastingPlan.sixteenHours,
        );
        final sessionToDeleteEndTime = DateTime.utc(2026, 6, 21, 1);
        tracker.end(actualEndTime: sessionToDeleteEndTime);
        tracker.start(
          startTime: DateTime.utc(2026, 6, 21, 8),
          plan: FastingPlan.sixteenHours,
        );
        final newestEndTime = DateTime.utc(2026, 6, 22, 1);
        tracker.end(actualEndTime: newestEndTime);
        final sessionToDelete = tracker.recentEndedSessions[1];

        tracker.deleteEndedSession(sessionToDelete.id);

        expect(
          tracker.recentEndedSessions.map((session) => session.actualEndTime),
          [newestEndTime, oldestEndTime],
        );
        expect(tracker.latestSession?.actualEndTime, newestEndTime);
      },
    );

    test('does not delete an active Fasting Session', () {
      final tracker = trackerAfterTestSessions();
      final startTime = DateTime.utc(2026, 6, 21, 8);
      tracker.start(startTime: startTime, plan: FastingPlan.sixteenHours);

      expect(() => tracker.deleteLatestEndedSession(), throwsStateError);
      expect(
        () => tracker.deleteEndedSession(tracker.activeSession!.id),
        throwsStateError,
      );

      expect(tracker.activeSession?.startTime, startTime);
      expect(tracker.status, FastingStatus.fasting);
    });

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

    test(
      'keeps Personal Fasting Activity ordered after correcting actual end time',
      () {
        final ids = [
          FastingSessionId('z-corrected'),
          FastingSessionId('a-tied'),
        ];
        final tracker = FastingTracker(
          nowUtc: () => DateTime.utc(2026, 6, 23),
          newSessionId: () => ids.removeAt(0),
        );
        tracker.start(
          startTime: DateTime.utc(2026, 6, 20, 8),
          plan: FastingPlan.sixteenHours,
        );
        tracker.end(actualEndTime: DateTime.utc(2026, 6, 22, 1));
        tracker.start(
          startTime: DateTime.utc(2026, 6, 19, 8),
          plan: FastingPlan.sixteenHours,
        );
        tracker.end(actualEndTime: DateTime.utc(2026, 6, 21, 1));

        tracker.correctActualEndTime(
          actualEndTime: DateTime.utc(2026, 6, 21, 1),
        );

        expect(tracker.recentEndedSessions.map((session) => session.id.value), [
          'a-tied',
          'z-corrected',
        ]);
        expect(tracker.latestSession?.id.value, 'a-tied');
      },
    );

    test(
      'correcting the latest ended Fasting Session updates recent history',
      () {
        final tracker = trackerAfterTestSessions();
        tracker.start(
          startTime: DateTime.utc(2026, 6, 20, 8),
          plan: FastingPlan.sixteenHours,
        );
        final olderEndTime = DateTime.utc(2026, 6, 21, 1);
        tracker.end(actualEndTime: olderEndTime);
        tracker.start(
          startTime: DateTime.utc(2026, 6, 21, 8),
          plan: FastingPlan.sixteenHours,
        );
        tracker.end(actualEndTime: DateTime.utc(2026, 6, 22, 1, 30));
        final correctedActualEndTime = DateTime.utc(2026, 6, 22, 0, 30);

        tracker.correctActualEndTime(actualEndTime: correctedActualEndTime);

        expect(
          tracker.recentEndedSessions.map((session) => session.actualEndTime),
          [correctedActualEndTime, olderEndTime],
        );
      },
    );

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
