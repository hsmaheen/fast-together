import 'package:fasting_app/domain/fasting_plan.dart';
import 'package:fasting_app/ui/components/fasting_plan_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders every preset Fasting Plan duration', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FastingPlanSelector(
            selectedPlan: FastingPlan.sixteenHours,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    for (final label in ['10h', '12h', '14h', '16h', '18h', '24h', '48h']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('marks the selected Fasting Plan', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FastingPlanSelector(
            selectedPlan: FastingPlan.sixteenHours,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    final selectedChip = tester.widget<ChoiceChip>(
      find.ancestor(of: find.text('16h'), matching: find.byType(ChoiceChip)),
    );
    final unselectedChip = tester.widget<ChoiceChip>(
      find.ancestor(of: find.text('24h'), matching: find.byType(ChoiceChip)),
    );

    expect(selectedChip.selected, isTrue);
    expect(unselectedChip.selected, isFalse);
  });

  testWidgets('emits the selected Fasting Plan when a duration is tapped', (
    tester,
  ) async {
    FastingPlan? changedPlan;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FastingPlanSelector(
            selectedPlan: FastingPlan.sixteenHours,
            onChanged: (plan) {
              changedPlan = plan;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('24h'));

    expect(changedPlan, same(FastingPlan.twentyFourHours));
  });
}
