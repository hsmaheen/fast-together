import 'package:fasting_app/domain/fasting_session.dart';
import 'package:fasting_app/ui/components/fasting_progress_ring.dart';
import 'package:fasting_app/ui/components/fasting_time_summary.dart';
import 'package:flutter/material.dart';

class ActiveFastingStatus extends StatelessWidget {
  const ActiveFastingStatus({
    required this.session,
    required this.currentTime,
    required this.onEndPressed,
    this.errorMessage,
    super.key,
  });

  final FastingSession session;
  final DateTime currentTime;
  final VoidCallback onEndPressed;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final elapsed = session.elapsedAt(currentTime);
    final targetDuration = session.targetEndTime.difference(session.startTime);
    final remaining = session.remainingAt(currentTime);
    final isOverTarget = remaining.isNegative;
    final heroLabel = isOverTarget ? 'Over Target' : 'Remaining';
    final heroDuration = isOverTarget
        ? session.overTargetAt(currentTime)
        : remaining;

    return Column(
      key: const ValueKey('activeFastingStatus'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Fasting', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Center(
          child: FastingProgressRing(
            progress: elapsed.inMinutes / targetDuration.inMinutes,
            isOverTarget: isOverTarget,
            size: 160,
            child: _HeroTimer(
              label: heroLabel,
              value: _formatDuration(heroDuration),
            ),
          ),
        ),
        const SizedBox(height: 20),
        FastingTimeSummary(
          startTime: session.startTime,
          targetEndTime: session.targetEndTime,
          elapsed: elapsed,
          remaining: null,
          overTarget: null,
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 20),
          Text(
            errorMessage!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          key: const ValueKey('endFastingSessionButton'),
          onPressed: onEndPressed,
          child: const Text('End Fasting Session'),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours == 0) {
      if (minutes == 0) {
        return '${seconds}s';
      }

      return '${minutes}m ${seconds}s';
    }

    return '${hours}h ${minutes}m ${seconds}s';
  }
}

class _HeroTimer extends StatelessWidget {
  const _HeroTimer({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 112,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
