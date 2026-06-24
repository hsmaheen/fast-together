import 'package:fasting_app/domain/fasting_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FastingPlanSelector extends StatefulWidget {
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
  static const _defaultCustomHours = 20;

  @override
  State<FastingPlanSelector> createState() => _FastingPlanSelectorState();
}

class _FastingPlanSelectorState extends State<FastingPlanSelector> {
  String? _customHoursError;

  @override
  Widget build(BuildContext context) {
    final isCustomPlan = _isCustomPlan(widget.selectedPlan);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final plan in FastingPlanSelector._presetPlans)
              ChoiceChip(
                label: Text('${plan.duration.inHours}h'),
                selected: identical(plan, widget.selectedPlan),
                onSelected: (_) {
                  setState(() {
                    _customHoursError = null;
                  });
                  widget.onChanged(plan);
                },
              ),
            ChoiceChip(
              label: const Text('Custom'),
              selected: isCustomPlan,
              onSelected: (_) {
                setState(() {
                  _customHoursError = null;
                });
                widget.onChanged(
                  FastingPlan.customHours(
                    FastingPlanSelector._defaultCustomHours,
                  ),
                );
              },
            ),
          ],
        ),
        if (isCustomPlan) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: 160,
            child: TextFormField(
              initialValue: widget.selectedPlan.duration.inHours.toString(),
              decoration: InputDecoration(
                labelText: 'Custom Hours',
                suffixText: 'hours',
                errorText: _customHoursError,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                final hours = int.tryParse(value);
                if (hours == null) {
                  setState(() {
                    _customHoursError = 'Enter 1-168 hours';
                  });
                  return;
                }

                try {
                  final plan = FastingPlan.customHours(hours);
                  setState(() {
                    _customHoursError = null;
                  });
                  widget.onChanged(plan);
                } on ArgumentError {
                  setState(() {
                    _customHoursError = 'Enter 1-168 hours';
                  });
                  return;
                }
              },
            ),
          ),
        ],
      ],
    );
  }

  bool _isCustomPlan(FastingPlan plan) {
    return !FastingPlanSelector._presetPlans.any(
      (presetPlan) => identical(presetPlan, plan),
    );
  }
}
