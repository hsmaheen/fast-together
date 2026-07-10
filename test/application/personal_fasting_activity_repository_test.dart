import 'package:fasting_app/application/fasting_tracker.dart';
import 'package:fasting_app/application/personal_fasting_activity_repository.dart';
import 'package:fasting_app/domain/fasting_plan.dart';
import 'package:fasting_app/domain/fasting_session.dart';
import 'package:fasting_app/domain/fasting_session_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppAccountId', () {
    test('rejects an empty value', () {
      expect(() => AppAccountId(''), throwsArgumentError);
    });
  });

  group('FastingTracker identity', () {
    test('does not reuse an ID from ended Personal Fasting Activity', () {
      final id = FastingSessionId('reused-session');
      final tracker = FastingTracker(
        nowUtc: () => DateTime.utc(2026, 6, 22, 2),
        newSessionId: () => id,
      );
      tracker.start(
        startTime: DateTime.utc(2026, 6, 20, 8),
        plan: FastingPlan.sixteenHours,
      );
      tracker.end(actualEndTime: DateTime.utc(2026, 6, 21, 1));

      expect(
        () => tracker.start(
          startTime: DateTime.utc(2026, 6, 21, 8),
          plan: FastingPlan.sixteenHours,
        ),
        throwsStateError,
      );
    });

    test('uses an injected ID for a new Fasting Session', () {
      final id = FastingSessionId('generated-session');
      final tracker = FastingTracker(
        nowUtc: () => DateTime.utc(2026, 6, 21, 2),
        newSessionId: () => id,
      );

      tracker.start(
        startTime: DateTime.utc(2026, 6, 20, 8),
        plan: FastingPlan.sixteenHours,
      );
      tracker.end(actualEndTime: DateTime.utc(2026, 6, 21, 1));

      expect(tracker.latestSession?.id, id);
    });
  });

  group('Personal Fasting Activity hydration', () {
    test('orders ended Fasting Sessions newest actual end time first', () {
      final olderSession = FastingSession(
        id: FastingSessionId('older-session'),
        startTime: DateTime.utc(2026, 6, 20, 8),
        targetEndTime: DateTime.utc(2026, 6, 21),
        actualEndTime: DateTime.utc(2026, 6, 21, 1),
      );
      final newerSession = FastingSession(
        id: FastingSessionId('newer-session'),
        startTime: DateTime.utc(2026, 6, 21, 8),
        targetEndTime: DateTime.utc(2026, 6, 22),
        actualEndTime: DateTime.utc(2026, 6, 22, 1),
      );

      final snapshot = PersonalFastingActivitySnapshot(
        endedSessions: [olderSession, newerSession],
      );

      expect(snapshot.endedSessions, [newerSession, olderSession]);
    });

    test('rejects duplicate Fasting Session IDs', () {
      final id = FastingSessionId('duplicate-session');
      final activeSession = FastingSession(
        id: id,
        startTime: DateTime.utc(2026, 6, 21, 8),
        targetEndTime: DateTime.utc(2026, 6, 22),
      );
      final endedSession = FastingSession(
        id: id,
        startTime: DateTime.utc(2026, 6, 20, 8),
        targetEndTime: DateTime.utc(2026, 6, 21),
        actualEndTime: DateTime.utc(2026, 6, 21, 1),
      );

      expect(
        () => PersonalFastingActivitySnapshot(
          activeSession: activeSession,
          endedSessions: [endedSession],
        ),
        throwsArgumentError,
      );
    });

    test('rejects an active Fasting Session in ended history', () {
      final activeSession = FastingSession(
        id: FastingSessionId('active-session'),
        startTime: DateTime.utc(2026, 6, 20, 8),
        targetEndTime: DateTime.utc(2026, 6, 21),
      );

      expect(
        () => PersonalFastingActivitySnapshot(endedSessions: [activeSession]),
        throwsArgumentError,
      );
    });

    test('preserves the persisted ID of an active Fasting Session', () {
      final id = FastingSessionId('active-session');
      final snapshot = PersonalFastingActivitySnapshot(
        activeSession: FastingSession(
          id: id,
          startTime: DateTime.utc(2026, 6, 20, 8),
          targetEndTime: DateTime.utc(2026, 6, 21),
        ),
      );

      final tracker = FastingTracker.fromSnapshot(snapshot: snapshot);

      expect(tracker.activeSession?.id, id);
    });

    test('preserves an ended session ID and derives its result', () {
      final id = FastingSessionId('ended-session');
      final snapshot = PersonalFastingActivitySnapshot(
        endedSessions: [
          FastingSession(
            id: id,
            startTime: DateTime.utc(2026, 6, 20, 8),
            targetEndTime: DateTime.utc(2026, 6, 21),
            actualEndTime: DateTime.utc(2026, 6, 21, 1),
          ),
        ],
      );

      final tracker = FastingTracker.fromSnapshot(snapshot: snapshot);

      expect(tracker.latestSession?.id, id);
      expect(tracker.latestSession?.result, FastingResult.completed);
    });
  });
}
