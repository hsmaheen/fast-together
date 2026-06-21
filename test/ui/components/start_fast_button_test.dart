import 'package:fasting_app/domain/fasting_plan.dart';
import 'package:fasting_app/ui/components/start_fast_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders start action copy for the selected Fasting Plan', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StartFastButton(
            selectedPlan: FastingPlan.sixteenHours,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Start 16h Fasting Session'), findsOneWidget);
  });

  testWidgets('calls onPressed when tapped', (tester) async {
    var pressCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StartFastButton(
            selectedPlan: FastingPlan.sixteenHours,
            onPressed: () {
              pressCount += 1;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(StartFastButton));

    expect(pressCount, 1);
  });

  testWidgets('is disabled when no start action is available', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StartFastButton(
            selectedPlan: FastingPlan.sixteenHours,
            onPressed: null,
          ),
        ),
      ),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));

    expect(button.onPressed, isNull);
  });
}
