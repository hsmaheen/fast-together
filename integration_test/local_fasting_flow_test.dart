import 'package:fasting_app/main.dart';
import 'package:fasting_app/ui/components/calendar_day_fasting_total.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('local fasting flow', () {
    testWidgets(
      'records multiple recent Personal Fasting Activity entries and deletes specific ended sessions',
      (tester) async {
        var now = DateTime.utc(2026, 6, 21, 8);

        await tester.pumpWidget(FastingApp(nowUtc: () => now));
        await tester.pumpAndSettle();

        expect(find.text('Not Fasting'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('personalFastingActivityEmptyState')),
          findsOneWidget,
        );

        await _tapByKey(tester, const ValueKey('startFastingSessionButton'));
        expect(
          find.byKey(const ValueKey('activeFastingStatus')),
          findsOneWidget,
        );
        expect(find.text('Fasting'), findsOneWidget);

        now = DateTime.utc(2026, 6, 22, 1);
        await _endFastingSession(tester);

        expect(find.text('Not Fasting'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('recentFastingSessionItem_0')),
          findsOneWidget,
        );
        expect(find.text('Completed'), findsOneWidget);

        await _tapByKey(tester, const ValueKey('startFastingSessionButton'));
        expect(
          find.byKey(const ValueKey('activeFastingStatus')),
          findsOneWidget,
        );

        now = DateTime.utc(2026, 6, 22, 11);
        await _endFastingSession(tester);

        expect(find.text('Not Fasting'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('personalFastingActivityList')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('recentFastingSessionItem_0')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('recentFastingSessionItem_1')),
          findsOneWidget,
        );
        expect(find.text('Ended Early'), findsOneWidget);
        expect(find.text('Completed'), findsOneWidget);

        await _tapByKey(
          tester,
          ValueKey('delete-${DateTime.utc(2026, 6, 22, 1)}'),
        );

        expect(
          find.byKey(const ValueKey('recentFastingSessionItem_0')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('recentFastingSessionItem_1')),
          findsNothing,
        );
        expect(find.text('Ended Early'), findsOneWidget);
        expect(find.text('Completed'), findsNothing);

        await _tapByKey(tester, const ValueKey('latestDeleteButton'));

        expect(
          find.byKey(const ValueKey('personalFastingActivityEmptyState')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('recentFastingSessionItem_0')),
          findsNothing,
        );
        expect(find.text('Ended Early'), findsNothing);
      },
    );

    testWidgets('shows daily totals from the user-facing calendar history', (
      tester,
    ) async {
      var now = DateTime.utc(2026, 6, 21, 8);
      final actualEndTime = DateTime.utc(2026, 6, 22);

      await tester.pumpWidget(FastingApp(nowUtc: () => now));
      await tester.pumpAndSettle();

      await _tapByKey(tester, const ValueKey('startFastingSessionButton'));

      now = actualEndTime;
      await _endFastingSession(tester);

      now = DateTime.utc(2026, 6, 23, 12);
      await _tapByKey(tester, const ValueKey('dailyFastingTotalsButton'));

      final localizations = MaterialLocalizations.of(
        tester.element(find.byType(CalendarDayFastingTotal)),
      );
      final localEndTime = actualEndTime.toLocal();
      final localEndDate = DateTime(
        localEndTime.year,
        localEndTime.month,
        localEndTime.day,
      );

      expect(find.text('Calendar-day fasting total'), findsOneWidget);
      expect(find.text('No fasting total for this day yet.'), findsOneWidget);

      await tester.tap(find.text(localizations.formatShortDate(localEndDate)));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(CalendarDayFastingTotal),
          matching: find.text(localizations.formatMediumDate(localEndDate)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(CalendarDayFastingTotal),
          matching: find.text('16h 0m'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('validates and starts a custom Fasting Plan', (tester) async {
      final now = DateTime.utc(2026, 6, 21, 8);

      await tester.pumpWidget(FastingApp(nowUtc: () => now));
      await tester.pumpAndSettle();

      await _tapByKey(tester, const ValueKey('fastingPlanCustomChip'));

      await tester.enterText(
        find.byKey(const ValueKey('customPlanHoursField')),
        '169',
      );
      await tester.pumpAndSettle();

      expect(find.text('Enter 1-168 hours'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('customPlanHoursField')),
        '36',
      );
      await tester.pumpAndSettle();

      expect(find.text('Start 36h Fasting Session'), findsOneWidget);

      await _tapByKey(tester, const ValueKey('startFastingSessionButton'));

      expect(find.byKey(const ValueKey('activeFastingStatus')), findsOneWidget);
      expect(find.text('36h 0m'), findsOneWidget);
    });

    testWidgets(
      'keeps an over-target Fasting Session active until the user ends it',
      (tester) async {
        var now = DateTime.utc(2026, 6, 21, 8);

        await tester.pumpWidget(FastingApp(nowUtc: () => now));
        await tester.pumpAndSettle();

        await _tapByKey(tester, const ValueKey('fastingPlanChip_10'));
        await _tapByKey(tester, const ValueKey('startFastingSessionButton'));

        expect(
          find.byKey(const ValueKey('activeFastingStatus')),
          findsOneWidget,
        );
        expect(find.text('Fasting'), findsOneWidget);
        expect(find.text('Remaining'), findsOneWidget);
        expect(find.text('10h 0m'), findsOneWidget);

        now = DateTime.utc(2026, 6, 21, 19, 30);
        await tester.pump(const Duration(minutes: 1));

        expect(
          find.byKey(const ValueKey('activeFastingStatus')),
          findsOneWidget,
        );
        expect(find.text('Not Fasting'), findsNothing);
        expect(find.text('Over Target'), findsOneWidget);
        expect(find.text('1h 30m'), findsOneWidget);
        expect(find.text('End Fasting Session'), findsOneWidget);

        await _openEndFastingSessionSheet(tester);

        expect(
          find.descendant(
            of: find.byKey(const ValueKey('endFastingSessionSheet')),
            matching: find.text('Total Fasting Time'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('endFastingSessionSheet')),
            matching: find.text('11h 30m'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('endFastingSessionSheet')),
            matching: find.text('Completed'),
          ),
          findsOneWidget,
        );

        await _tapByKey(
          tester,
          const ValueKey('confirmEndFastingSessionButton'),
        );

        expect(find.text('Not Fasting'), findsOneWidget);
        expect(find.byKey(const ValueKey('activeFastingStatus')), findsNothing);
        expect(
          find.byKey(const ValueKey('recentFastingSessionItem_0')),
          findsOneWidget,
        );
        expect(find.text('Completed'), findsOneWidget);
        expect(find.text('11h 30m'), findsOneWidget);
      },
    );

    testWidgets('starts a Fasting Session from a corrected start time', (
      tester,
    ) async {
      final now = DateTime.utc(2026, 6, 21, 8);
      final correctedStartTime = DateTime.utc(2026, 6, 21, 4);

      await tester.pumpWidget(
        FastingApp(
          nowUtc: () => now,
          selectStartTime: (_, _) async => correctedStartTime,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await _tapByKey(tester, const ValueKey('startFastingSessionButton'));

      expect(find.byKey(const ValueKey('activeFastingStatus')), findsOneWidget);
      expect(find.text('Fasting'), findsOneWidget);
      expect(find.text('Elapsed'), findsOneWidget);
      expect(find.text('4h 0m'), findsOneWidget);
      expect(find.text('Remaining'), findsOneWidget);
      expect(find.text('12h 0m'), findsOneWidget);
    });

    testWidgets(
      'ends a Fasting Session from a corrected actual end time through the sheet',
      (tester) async {
        var now = DateTime.utc(2026, 6, 21, 8);
        final correctedActualEndTime = DateTime.utc(2026, 6, 21, 23, 45);

        await tester.pumpWidget(
          FastingApp(
            nowUtc: () => now,
            selectActualEndTime: (_, selectedActualEndTime) async {
              expect(selectedActualEndTime, DateTime.utc(2026, 6, 22, 1));
              return correctedActualEndTime;
            },
          ),
        );
        await tester.pumpAndSettle();

        await _tapByKey(tester, const ValueKey('startFastingSessionButton'));
        expect(
          find.byKey(const ValueKey('activeFastingStatus')),
          findsOneWidget,
        );

        now = DateTime.utc(2026, 6, 22, 1);
        await _openEndFastingSessionSheet(tester);

        await _editEndFastingSessionActualEndTime(tester);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('endFastingSessionSheet')),
            matching: find.text('15h 45m'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('endFastingSessionSheet')),
            matching: find.text('Ended Early'),
          ),
          findsOneWidget,
        );

        await _tapByKey(
          tester,
          const ValueKey('confirmEndFastingSessionButton'),
        );

        expect(find.text('Not Fasting'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('personalFastingActivityList')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('recentFastingSessionItem_0')),
          findsOneWidget,
        );
        expect(find.text('Latest Fasting Session'), findsOneWidget);
        expect(find.text('Ended Early'), findsOneWidget);
        expect(find.text('15h 45m'), findsOneWidget);
        expect(
          find.text(_formatLocalDateAndTime(tester, correctedActualEndTime)),
          findsOneWidget,
        );
      },
    );
  });
}

Future<void> _tapByKey(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _endFastingSession(WidgetTester tester) async {
  await _openEndFastingSessionSheet(tester);
  await tester.tap(
    find.byKey(const ValueKey('confirmEndFastingSessionButton')),
  );
  await tester.pumpAndSettle();
}

Future<void> _openEndFastingSessionSheet(WidgetTester tester) async {
  await _tapByKey(tester, const ValueKey('endFastingSessionButton'));
  expect(find.byKey(const ValueKey('endFastingSessionSheet')), findsOneWidget);
}

Future<void> _editEndFastingSessionActualEndTime(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(const ValueKey('endFastingSessionSheet')),
      matching: find.text('Edit'),
    ),
  );
  await tester.pumpAndSettle();
}

String _formatLocalDateAndTime(WidgetTester tester, DateTime value) {
  final context = tester.element(
    find.byKey(const ValueKey('recentFastingSessionItem_0')),
  );
  final localizations = MaterialLocalizations.of(context);
  final localValue = value.toLocal();
  final date = localizations.formatMediumDate(localValue);
  final time = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(localValue),
  );

  return '$date $time';
}
