import 'package:fasting_app/application/fasting_tracker.dart';
import 'package:fasting_app/domain/fasting_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FastingTracker', () {
    test('starts as Not Fasting', () {
      final tracker = FastingTracker();

      expect(tracker.status, FastingStatus.notFasting);
    });

    test('starts a current Fasting Session from a Fasting Plan', () {
      final tracker = FastingTracker();
      final startTime = DateTime.utc(2026, 6, 21, 8);

      tracker.start(startTime: startTime, plan: FastingPlan.sixteenHours);

      expect(tracker.currentSession?.isActive, isTrue);
      expect(tracker.currentSession?.startTime, startTime);
      expect(tracker.currentSession?.targetEndTime, DateTime.utc(2026, 6, 22));
    });

    test('reports Fasting after starting', () {
      final tracker = FastingTracker();

      tracker.start(
        startTime: DateTime.utc(2026, 6, 21, 8),
        plan: FastingPlan.sixteenHours,
      );

      expect(tracker.status, FastingStatus.fasting);
    });

    test('does not start while already Fasting', () {
      final tracker = FastingTracker();
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

    test('ends the current Fasting Session', () {
      final tracker = FastingTracker();
      tracker.start(
        startTime: DateTime.utc(2026, 6, 21, 8),
        plan: FastingPlan.sixteenHours,
      );
      final actualEndTime = DateTime.utc(2026, 6, 22, 1);

      tracker.end(actualEndTime: actualEndTime);

      expect(tracker.currentSession?.isActive, isFalse);
      expect(tracker.currentSession?.actualEndTime, actualEndTime);
    });

    test('reports Not Fasting after ending', () {
      final tracker = FastingTracker();
      tracker.start(
        startTime: DateTime.utc(2026, 6, 21, 8),
        plan: FastingPlan.sixteenHours,
      );

      tracker.end(actualEndTime: DateTime.utc(2026, 6, 22, 1));

      expect(tracker.status, FastingStatus.notFasting);
    });

    test('does not end when Not Fasting', () {
      final tracker = FastingTracker();

      expect(
        () => tracker.end(actualEndTime: DateTime.utc(2026, 6, 22, 1)),
        throwsStateError,
      );
    });
  });
}
