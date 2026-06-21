import 'package:fasting_app/domain/fasting_plan.dart';
import 'package:fasting_app/domain/fasting_session.dart';
import 'package:fasting_app/ui/components/latest_fasting_session_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows completed Fasting Result for a completed session', (
    tester,
  ) async {
    final session = FastingSession.start(
      startTime: DateTime.utc(2026, 6, 21, 4),
      plan: FastingPlan.sixteenHours,
    ).end(actualEndTime: DateTime.utc(2026, 6, 21, 20));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LatestFastingSessionSummary(session: session)),
      ),
    );

    expect(find.text('Latest Fasting Session'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Actual Duration'), findsOneWidget);
    expect(find.text('16h 0m'), findsOneWidget);
  });

  testWidgets('does not show active Fasting Session details', (tester) async {
    final session = FastingSession.start(
      startTime: DateTime.utc(2026, 6, 21, 4),
      plan: FastingPlan.sixteenHours,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LatestFastingSessionSummary(session: session)),
      ),
    );

    expect(find.text('Latest Fasting Session'), findsNothing);
  });

  testWidgets('fits compact mobile width', (tester) async {
    final session = FastingSession.start(
      startTime: DateTime.utc(2026, 6, 21, 4),
      plan: FastingPlan.sixteenHours,
    ).end(actualEndTime: DateTime.utc(2026, 6, 21, 5, 30));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: LatestFastingSessionSummary(session: session),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Latest Fasting Session'), findsOneWidget);
  });
}
