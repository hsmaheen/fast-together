import 'package:fasting_app/domain/fasting_plan.dart';
import 'package:fasting_app/domain/fasting_session.dart';
import 'package:fasting_app/ui/components/active_fasting_status.dart';
import 'package:fasting_app/ui/components/fasting_progress_ring.dart';
import 'package:fasting_app/ui/components/fasting_time_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows active Fasting Status using Fasting Session data', (
    tester,
  ) async {
    final session = FastingSession.start(
      startTime: DateTime.utc(2026, 6, 21),
      plan: FastingPlan.sixteenHours,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActiveFastingStatus(
            session: session,
            currentTime: DateTime.utc(2026, 6, 21, 4, 15),
            onEndPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Fasting'), findsOneWidget);
    expect(find.text('Elapsed'), findsOneWidget);
    expect(find.text('4h 15m'), findsOneWidget);
    expect(find.text('Remaining'), findsOneWidget);
    expect(find.text('11h 45m 0s'), findsOneWidget);
    expect(find.text('Actual End Time'), findsNothing);
  });

  testWidgets('includes reviewed timing and progress components', (
    tester,
  ) async {
    final session = FastingSession.start(
      startTime: DateTime.utc(2026, 6, 21),
      plan: FastingPlan.sixteenHours,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActiveFastingStatus(
            session: session,
            currentTime: DateTime.utc(2026, 6, 21, 8),
            onEndPressed: () {},
          ),
        ),
      ),
    );

    expect(find.byType(FastingProgressRing), findsOneWidget);
    expect(find.byType(FastingTimeSummary), findsOneWidget);
  });

  testWidgets(
    'presents remaining time as the hero timer in the progress ring',
    (tester) async {
      final session = FastingSession.start(
        startTime: DateTime.utc(2026, 6, 21),
        plan: FastingPlan.sixteenHours,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActiveFastingStatus(
              session: session,
              currentTime: DateTime.utc(2026, 6, 21, 4, 15),
              onEndPressed: () {},
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(FastingProgressRing)).width, 160);
      expect(
        find.descendant(
          of: find.byType(FastingProgressRing),
          matching: find.text('Remaining'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(FastingProgressRing),
          matching: find.text('11h 45m 0s'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('shows seconds in the active hero timer', (tester) async {
    final session = FastingSession.start(
      startTime: DateTime.utc(2026, 6, 21),
      plan: FastingPlan.sixteenHours,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActiveFastingStatus(
            session: session,
            currentTime: DateTime.utc(2026, 6, 21, 4, 15, 30),
            onEndPressed: () {},
          ),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(FastingProgressRing),
        matching: find.text('11h 44m 30s'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('keeps over-24-hour hero time readable', (tester) async {
    final session = FastingSession.start(
      startTime: DateTime.utc(2026, 6, 21),
      plan: FastingPlan.customHours(48),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActiveFastingStatus(
            session: session,
            currentTime: DateTime.utc(2026, 6, 21, 12, 0, 30),
            onEndPressed: () {},
          ),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(FastingProgressRing),
        matching: find.text('35h 59m 30s'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('calls onEndPressed when the end action is tapped', (
    tester,
  ) async {
    var endPressCount = 0;
    final session = FastingSession.start(
      startTime: DateTime.utc(2026, 6, 21),
      plan: FastingPlan.sixteenHours,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActiveFastingStatus(
            session: session,
            currentTime: DateTime.utc(2026, 6, 21, 8),
            onEndPressed: () {
              endPressCount += 1;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('End Fasting Session'));

    expect(endPressCount, 1);
  });

  testWidgets('shows over-target time after target end time passes', (
    tester,
  ) async {
    final session = FastingSession.start(
      startTime: DateTime.utc(2026, 6, 21),
      plan: FastingPlan.sixteenHours,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActiveFastingStatus(
            session: session,
            currentTime: DateTime.utc(2026, 6, 21, 17, 30),
            onEndPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Remaining'), findsNothing);
    expect(find.text('Over Target'), findsOneWidget);
    expect(find.text('1h 30m 0s'), findsOneWidget);
  });

  testWidgets('fits narrow screens with large text', (tester) async {
    final session = FastingSession.start(
      startTime: DateTime.utc(2026, 6, 21),
      plan: FastingPlan.sixteenHours,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(240, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 240,
                child: ActiveFastingStatus(
                  session: session,
                  currentTime: DateTime.utc(2026, 6, 21, 4, 15),
                  onEndPressed: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Fasting'), findsOneWidget);
    expect(find.text('End Fasting Session'), findsOneWidget);
  });
}
