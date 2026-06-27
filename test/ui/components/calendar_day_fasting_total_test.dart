import 'package:fasting_app/application/fasting_tracker.dart';
import 'package:fasting_app/ui/components/calendar_day_fasting_total.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows fasting total for the selected calendar date', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarDayFastingTotal(
            selectedDate: DateTime(2026, 6, 21),
            dailyTotals: [
              DailyFastingTotal(
                date: DateTime(2026, 6, 21),
                duration: const Duration(hours: 16, minutes: 30),
              ),
            ],
          ),
        ),
      ),
    );

    final localizations = MaterialLocalizations.of(
      tester.element(find.byType(CalendarDayFastingTotal)),
    );

    expect(
      find.text(localizations.formatMediumDate(DateTime(2026, 6, 21))),
      findsOneWidget,
    );
    expect(find.text('16h 30m'), findsOneWidget);
  });

  testWidgets(
    'shows calm empty state when selected calendar date has no total',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarDayFastingTotal(
              selectedDate: DateTime(2026, 6, 22),
              dailyTotals: [
                DailyFastingTotal(
                  date: DateTime(2026, 6, 21),
                  duration: const Duration(hours: 16, minutes: 30),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('No fasting total for this day yet.'), findsOneWidget);
      expect(find.text('16h 30m'), findsNothing);
    },
  );
}
