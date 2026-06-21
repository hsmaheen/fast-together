import 'dart:async';

import 'package:fasting_app/ui/components/start_time_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('displays the selected start date and time', (tester) async {
    final selectedStartTime = DateTime.utc(2026, 6, 21, 4, 15);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StartTimeSelector(
            selectedStartTime: selectedStartTime,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    final localizations = MaterialLocalizations.of(
      tester.element(find.byType(StartTimeSelector)),
    );
    final expectedStartTime = _formatDateAndTime(
      localizations,
      selectedStartTime,
    );

    expect(find.text('Start Time'), findsOneWidget);
    expect(find.text(expectedStartTime), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
  });

  testWidgets('fits the selected start date and edit action in compact width', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            child: StartTimeSelector(
              selectedStartTime: DateTime.utc(2026, 6, 21, 4, 15),
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
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

  testWidgets('emits a corrected UTC start time from a previous date', (
    tester,
  ) async {
    DateTime? changedStartTime;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StartTimeSelector(
            selectedStartTime: DateTime.utc(2026, 6, 21, 4, 15),
            onChanged: (value) {
              changedStartTime = value;
            },
            selectDate: (_, _) async => DateTime(2026, 6, 20),
            selectClockTime: (_, _) async =>
                const TimeOfDay(hour: 8, minute: 30),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Edit'));
    await tester.pump();

    expect(changedStartTime, DateTime(2026, 6, 20, 8, 30).toUtc());
    expect(changedStartTime?.isUtc, isTrue);
  });

  testWidgets('does not emit a corrected start time after disposal', (
    tester,
  ) async {
    final pickerResult = Completer<DateTime?>();
    var didChange = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StartTimeSelector(
            selectedStartTime: DateTime.utc(2026, 6, 21, 4, 15),
            onChanged: (_) {
              didChange = true;
            },
            selectStartTime: (_, _) => pickerResult.future,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Edit'));
    await tester.pump();

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
    );

    pickerResult.complete(DateTime.utc(2026, 6, 21, 0, 15));
    await tester.pump();

    expect(didChange, isFalse);
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
