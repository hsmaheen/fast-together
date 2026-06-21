import 'package:fasting_app/ui/components/fasting_time_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows start time and target end time', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FastingTimeSummary(
            startTime: DateTime.utc(2026, 6, 21, 0),
            targetEndTime: DateTime.utc(2026, 6, 21, 16),
            elapsed: const Duration(hours: 4),
            remaining: const Duration(hours: 12),
          ),
        ),
      ),
    );

    expect(find.text('Start Time'), findsOneWidget);
    expect(find.text('Target End Time'), findsOneWidget);
  });

  testWidgets('shows elapsed and remaining time', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FastingTimeSummary(
            startTime: DateTime.utc(2026, 6, 21, 0),
            targetEndTime: DateTime.utc(2026, 6, 21, 16),
            elapsed: const Duration(hours: 4, minutes: 15),
            remaining: const Duration(hours: 11, minutes: 45),
          ),
        ),
      ),
    );

    expect(find.text('Elapsed'), findsOneWidget);
    expect(find.text('4h 15m'), findsOneWidget);
    expect(find.text('Remaining'), findsOneWidget);
    expect(find.text('11h 45m'), findsOneWidget);
  });

  testWidgets('shows over-target time instead of remaining time', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FastingTimeSummary(
            startTime: DateTime.utc(2026, 6, 21, 0),
            targetEndTime: DateTime.utc(2026, 6, 21, 16),
            elapsed: const Duration(hours: 17, minutes: 30),
            remaining: null,
            overTarget: const Duration(hours: 1, minutes: 30),
          ),
        ),
      ),
    );

    expect(find.text('Remaining'), findsNothing);
    expect(find.text('Over Target'), findsOneWidget);
    expect(find.text('1h 30m'), findsOneWidget);
  });
}
