import 'package:fasting_app/domain/fasting_plan.dart';
import 'package:fasting_app/domain/fasting_session.dart';
import 'package:fasting_app/ui/components/recent_fasting_sessions_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows Personal Fasting Activity empty state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RecentFastingSessionsList(sessions: [])),
      ),
    );

    expect(find.text('Personal Fasting Activity'), findsOneWidget);
    expect(find.text('No recent Fasting Sessions yet.'), findsOneWidget);
  });

  testWidgets('shows Fasting Result, actual duration, and actual end time', (
    tester,
  ) async {
    final session = FastingSession.start(
      startTime: DateTime.utc(2026, 6, 21, 4),
      plan: FastingPlan.sixteenHours,
    ).end(actualEndTime: DateTime.utc(2026, 6, 21, 20, 30));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RecentFastingSessionsList(sessions: [session])),
      ),
    );

    final localizations = MaterialLocalizations.of(
      tester.element(find.byType(RecentFastingSessionsList)),
    );

    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('16h 30m'), findsOneWidget);
    expect(
      find.text(_formatDateAndTime(localizations, session.actualEndTime!)),
      findsOneWidget,
    );
  });

  testWidgets('renders multiple ended Fasting Sessions as separate items', (
    tester,
  ) async {
    final completedSession = FastingSession.start(
      startTime: DateTime.utc(2026, 6, 21, 4),
      plan: FastingPlan.sixteenHours,
    ).end(actualEndTime: DateTime.utc(2026, 6, 21, 20));
    final endedEarlySession = FastingSession.start(
      startTime: DateTime.utc(2026, 6, 22, 4),
      plan: FastingPlan.sixteenHours,
    ).end(actualEndTime: DateTime.utc(2026, 6, 22, 18));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecentFastingSessionsList(
            sessions: [completedSession, endedEarlySession],
          ),
        ),
      ),
    );

    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Ended Early'), findsOneWidget);
    expect(find.text('Actual End Time'), findsNWidgets(2));
  });
}

String _formatDateAndTime(MaterialLocalizations localizations, DateTime value) {
  final localValue = value.toLocal();
  final date = localizations.formatMediumDate(localValue);
  final time = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(localValue),
  );

  return '$date $time';
}
