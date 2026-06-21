import 'package:fasting_app/domain/fasting_session.dart';
import 'package:fasting_app/ui/components/fasting_progress_ring.dart';
import 'package:fasting_app/ui/components/fasting_time_summary.dart';
import 'package:flutter/material.dart';

class ActiveFastingStatus extends StatelessWidget {
  const ActiveFastingStatus({
    required this.session,
    required this.currentTime,
    required this.onEndPressed,
    super.key,
  });

  final FastingSession session;
  final DateTime currentTime;
  final VoidCallback onEndPressed;

  @override
  Widget build(BuildContext context) {
    final elapsed = session.elapsedAt(currentTime);
    final targetDuration = session.targetEndTime.difference(session.startTime);
    final remaining = session.remainingAt(currentTime);
    final isOverTarget = remaining.isNegative;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Fasting',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
            final shouldStack = constraints.maxWidth < 360 || textScale > 1.3;
            final progressRing = FastingProgressRing(
              progress: elapsed.inMinutes / targetDuration.inMinutes,
              isOverTarget: isOverTarget,
            );
            final timeSummary = FastingTimeSummary(
              startTime: session.startTime,
              targetEndTime: session.targetEndTime,
              elapsed: elapsed,
              remaining: isOverTarget ? null : remaining,
              overTarget: isOverTarget
                  ? session.overTargetAt(currentTime)
                  : null,
            );

            if (shouldStack) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  progressRing,
                  const SizedBox(height: 16),
                  timeSummary,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                progressRing,
                const SizedBox(width: 20),
                Expanded(child: timeSummary),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: onEndPressed,
          child: const Text('End Fasting Session'),
        ),
      ],
    );
  }
}
