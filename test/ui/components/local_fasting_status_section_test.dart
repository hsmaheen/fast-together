import 'package:fasting_app/application/fasting_tracker.dart';
import 'package:fasting_app/domain/fasting_session.dart';
import 'package:fasting_app/ui/components/fasting_plan_selector.dart';
import 'package:fasting_app/ui/components/active_fasting_status.dart';
import 'package:fasting_app/ui/components/latest_fasting_session_summary.dart';
import 'package:fasting_app/ui/components/local_fasting_status_section.dart';
import 'package:fasting_app/ui/components/start_fast_button.dart';
import 'package:fasting_app/ui/components/start_time_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('starts as Not Fasting with plan selection and start action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocalFastingStatusSection(
            nowUtc: () => DateTime.utc(2026, 6, 21, 4, 15),
          ),
        ),
      ),
    );

    expect(find.text('Not Fasting'), findsOneWidget);
    expect(find.byType(FastingPlanSelector), findsOneWidget);
    expect(find.byType(StartTimeSelector), findsOneWidget);
    expect(find.byType(StartFastButton), findsOneWidget);
    expect(find.text('Start 16h Fasting Session'), findsOneWidget);
  });

  testWidgets('starts a local active Fasting Session from the selected plan', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocalFastingStatusSection(
            nowUtc: () => DateTime.utc(2026, 6, 21, 4, 15),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Start 16h Fasting Session'));
    await tester.pump();

    expect(find.text('Not Fasting'), findsNothing);
    expect(find.byType(ActiveFastingStatus), findsOneWidget);
    expect(find.text('Fasting'), findsOneWidget);
    expect(find.text('Remaining'), findsOneWidget);
    expect(find.text('16h 0m'), findsOneWidget);
  });

  testWidgets('updates active Fasting Status as time passes', (tester) async {
    var now = DateTime.utc(2026, 6, 21, 4, 15);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LocalFastingStatusSection(nowUtc: () => now)),
      ),
    );

    await tester.tap(find.text('Start 16h Fasting Session'));
    await tester.pump();

    expect(find.text('16h 0m'), findsOneWidget);

    now = DateTime.utc(2026, 6, 21, 4, 16);
    await tester.pump(const Duration(minutes: 1));

    expect(find.text('Elapsed'), findsOneWidget);
    expect(find.text('1m'), findsOneWidget);
    expect(find.text('Remaining'), findsOneWidget);
    expect(find.text('15h 59m'), findsOneWidget);
  });

  testWidgets('starts a Fasting Session from the corrected start time', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocalFastingStatusSection(
            nowUtc: () => DateTime.utc(2026, 6, 21, 4, 15),
            selectStartTime: (_, _) async => DateTime.utc(2026, 6, 21, 0, 15),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Edit'));
    await tester.pump();
    await tester.tap(find.text('Start 16h Fasting Session'));
    await tester.pump();

    expect(find.byType(ActiveFastingStatus), findsOneWidget);
    expect(find.text('Elapsed'), findsOneWidget);
    expect(find.text('4h 0m'), findsOneWidget);
    expect(find.text('Remaining'), findsOneWidget);
    expect(find.text('12h 0m'), findsOneWidget);
  });

  testWidgets('does not start from a future corrected start time', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocalFastingStatusSection(
            nowUtc: () => DateTime.utc(2026, 6, 21, 4, 15),
            selectStartTime: (_, _) async => DateTime.utc(2026, 6, 21, 4, 16),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Edit'));
    await tester.pump();
    await tester.tap(find.text('Start 16h Fasting Session'));
    await tester.pump();

    expect(find.byType(ActiveFastingStatus), findsNothing);
    expect(find.text('Not Fasting'), findsOneWidget);
    expect(find.text('Start time cannot be in the future'), findsOneWidget);
  });

  testWidgets('returns to Not Fasting when the active Fasting Session ends', (
    tester,
  ) async {
    var now = DateTime.utc(2026, 6, 21, 4, 15);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LocalFastingStatusSection(nowUtc: () => now)),
      ),
    );

    await tester.tap(find.text('Start 16h Fasting Session'));
    await tester.pump();

    now = DateTime.utc(2026, 6, 21, 4, 16);
    await tester.tap(find.text('End Fasting Session'));
    await tester.pump();

    expect(find.text('Not Fasting'), findsOneWidget);
    expect(find.byType(ActiveFastingStatus), findsNothing);
    expect(find.byType(FastingPlanSelector), findsOneWidget);
    expect(find.byType(StartFastButton), findsOneWidget);
  });

  testWidgets('records an ended Fasting Session through FastingTracker', (
    tester,
  ) async {
    var now = DateTime.utc(2026, 6, 21, 4, 15);
    final tracker = FastingTracker(nowUtc: () => now);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocalFastingStatusSection(nowUtc: () => now, tracker: tracker),
        ),
      ),
    );

    await tester.tap(find.text('Start 16h Fasting Session'));
    await tester.pump();

    now = DateTime.utc(2026, 6, 21, 5, 15);
    await tester.tap(find.text('End Fasting Session'));
    await tester.pump();

    expect(tracker.activeSession, isNull);
    expect(tracker.latestSession?.actualEndTime, now);
    expect(tracker.latestSession?.actualDuration, const Duration(hours: 1));
    expect(tracker.latestSession?.result, FastingResult.endedEarly);
  });

  testWidgets('shows a latest ended Fasting Session summary after ending', (
    tester,
  ) async {
    var now = DateTime.utc(2026, 6, 21, 4, 15);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LocalFastingStatusSection(nowUtc: () => now)),
      ),
    );

    await tester.tap(find.text('Start 16h Fasting Session'));
    await tester.pump();

    now = DateTime.utc(2026, 6, 21, 5, 45);
    await tester.tap(find.text('End Fasting Session'));
    await tester.pump();

    final localizations = MaterialLocalizations.of(
      tester.element(find.byType(LocalFastingStatusSection)),
    );

    expect(find.text('Not Fasting'), findsOneWidget);
    expect(find.text('Latest Fasting Session'), findsOneWidget);
    expect(find.text('Ended Early'), findsOneWidget);
    expect(find.text('Actual Duration'), findsOneWidget);
    expect(find.text('1h 30m'), findsOneWidget);
    expect(find.text('Actual End Time'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(LatestFastingSessionSummary),
        matching: find.text(_formatDateAndTime(localizations, now)),
      ),
      findsOneWidget,
    );
  });

  testWidgets('ends a Fasting Session from the corrected actual end time', (
    tester,
  ) async {
    var now = DateTime.utc(2026, 6, 21, 4, 15);
    final tracker = FastingTracker(nowUtc: () => now);
    final correctedActualEndTime = DateTime.utc(2026, 6, 21, 4, 45);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocalFastingStatusSection(
            nowUtc: () => now,
            tracker: tracker,
            selectActualEndTime: (_, _) async => correctedActualEndTime,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Start 16h Fasting Session'));
    await tester.pump();

    now = DateTime.utc(2026, 6, 21, 5, 15);
    await tester.tap(find.text('Edit'));
    await tester.pump();
    await tester.tap(find.text('End Fasting Session'));
    await tester.pump();

    expect(tracker.activeSession, isNull);
    expect(tracker.latestSession?.actualEndTime, correctedActualEndTime);
    expect(tracker.latestSession?.actualDuration, const Duration(minutes: 30));
    expect(tracker.latestSession?.result, FastingResult.endedEarly);
  });

  testWidgets('does not end from a future corrected actual end time', (
    tester,
  ) async {
    var now = DateTime.utc(2026, 6, 21, 4, 15);
    final tracker = FastingTracker(nowUtc: () => now);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocalFastingStatusSection(
            nowUtc: () => now,
            tracker: tracker,
            selectActualEndTime: (_, _) async =>
                DateTime.utc(2026, 6, 21, 5, 16),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Start 16h Fasting Session'));
    await tester.pump();

    now = DateTime.utc(2026, 6, 21, 5, 15);
    await tester.tap(find.text('Edit'));
    await tester.pump();
    await tester.tap(find.text('End Fasting Session'));
    await tester.pump();

    expect(tracker.activeSession, isNotNull);
    expect(find.text('Fasting'), findsOneWidget);
    expect(
      find.text('Actual end time cannot be in the future'),
      findsOneWidget,
    );
  });

  testWidgets('does not end before the Fasting Session start time', (
    tester,
  ) async {
    var now = DateTime.utc(2026, 6, 21, 4, 15);
    final tracker = FastingTracker(nowUtc: () => now);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocalFastingStatusSection(
            nowUtc: () => now,
            tracker: tracker,
            selectActualEndTime: (_, _) async =>
                DateTime.utc(2026, 6, 21, 4, 14),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Start 16h Fasting Session'));
    await tester.pump();

    now = DateTime.utc(2026, 6, 21, 5, 15);
    await tester.tap(find.text('Edit'));
    await tester.pump();
    await tester.tap(find.text('End Fasting Session'));
    await tester.pump();

    expect(tracker.activeSession, isNotNull);
    expect(find.text('Fasting'), findsOneWidget);
    expect(
      find.text('Actual end time must be after the start time'),
      findsOneWidget,
    );
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
