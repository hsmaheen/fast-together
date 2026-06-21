import 'package:fasting_app/domain/fasting_plan.dart';
import 'package:flutter/material.dart';

class FastingPlanSelector extends StatelessWidget {
  const FastingPlanSelector({
    required this.selectedPlan,
    required this.onChanged,
    super.key,
  });

  final FastingPlan selectedPlan;
  final ValueChanged<FastingPlan> onChanged;

  static const _presetPlans = [
    FastingPlan.tenHours,
    FastingPlan.twelveHours,
    FastingPlan.fourteenHours,
    FastingPlan.sixteenHours,
    FastingPlan.eighteenHours,
    FastingPlan.twentyFourHours,
    FastingPlan.fortyEightHours,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final plan in _presetPlans)
          ChoiceChip(
            label: Text('${plan.duration.inHours}h'),
            selected: identical(plan, selectedPlan),
            onSelected: (_) => onChanged(plan),
          ),
      ],
    );
  }
}
