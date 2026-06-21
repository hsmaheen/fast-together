import 'package:fasting_app/domain/fasting_plan.dart';
import 'package:flutter/material.dart';

class StartFastButton extends StatelessWidget {
  const StartFastButton({
    required this.selectedPlan,
    required this.onPressed,
    super.key,
  });

  final FastingPlan selectedPlan;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      child: Text('Start ${selectedPlan.duration.inHours}h Fasting Session'),
    );
  }
}
