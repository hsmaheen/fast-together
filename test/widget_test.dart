import 'package:fasting_app/application/fasting_tracker.dart';
import 'package:fasting_app/domain/fasting_plan.dart';
import 'package:fasting_app/main.dart';
import 'package:fasting_app/ui/components/calendar_day_fasting_total.dart';
import 'package:fasting_app/ui/components/local_fasting_status_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows local Fasting Status on app launch', (tester) async {
    await tester.pumpWidget(const FastingApp());

    expect(find.text('Fasting App'), findsOneWidget);
    expect(find.byType(LocalFastingStatusSection), findsOneWidget);
    expect(find.text('Not Fasting'), findsOneWidget);
    expect(find.text('Start 16h Fasting Session'), findsOneWidget);

    expect(find.text('Flutter Demo Home Page'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('opens local calendar-day fasting totals from app launch', (
    tester,
  ) async {
    var now = DateTime.utc(2026, 6, 23, 12);
    final tracker = FastingTracker(nowUtc: () => now);
    final actualEndTime = DateTime.utc(2026, 6, 21, 20);

    tracker.start(
      startTime: DateTime.utc(2026, 6, 21, 4),
      plan: FastingPlan.sixteenHours,
    );
    tracker.end(actualEndTime: actualEndTime);

    await tester.pumpWidget(FastingApp(nowUtc: () => now, tracker: tracker));
    await tester.tap(find.text('Daily totals'));
    await tester.pumpAndSettle();

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
    await tester.pump();

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
}
