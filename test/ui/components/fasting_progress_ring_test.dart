import 'package:fasting_app/ui/components/fasting_progress_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('represents progress toward the target end time', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FastingProgressRing(progress: 0.25)),
      ),
    );

    final indicator = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );

    expect(indicator.value, 0.25);
  });

  testWidgets('represents over-target state without exceeding full progress', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FastingProgressRing(progress: 1.25, isOverTarget: true),
        ),
      ),
    );

    final indicator = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );

    expect(indicator.value, 1);
    expect(indicator.semanticsLabel, 'Fasting progress over target');
    expect(indicator.semanticsValue, '100%');
  });

  testWidgets('shows centered hero content inside the progress ring', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FastingProgressRing(progress: 0.25, child: Text('11h 45m')),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(FastingProgressRing),
        matching: find.text('11h 45m'),
      ),
      findsOneWidget,
    );
  });
}
