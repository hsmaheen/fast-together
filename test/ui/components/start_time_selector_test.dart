import 'package:fasting_app/ui/components/start_time_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('displays the selected start time', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StartTimeSelector(
            selectedStartTime: DateTime.utc(2026, 6, 21, 4, 15),
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Start Time'), findsOneWidget);
    expect(find.text('12:15 PM'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
  });

  testWidgets('emits the corrected UTC start time', (tester) async {
    DateTime? changedStartTime;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StartTimeSelector(
            selectedStartTime: DateTime.utc(2026, 6, 21, 4, 15),
            onChanged: (value) {
              changedStartTime = value;
            },
            selectStartTime: (_, _) async => DateTime.utc(2026, 6, 21, 0, 15),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Edit'));
    await tester.pump();

    expect(changedStartTime, DateTime.utc(2026, 6, 21, 0, 15));
    expect(changedStartTime?.isUtc, isTrue);
  });
}
