import 'package:fasting_app/domain/fasting_session.dart';
import 'package:flutter/material.dart';

class LatestFastingSessionSummary extends StatelessWidget {
  const LatestFastingSessionSummary({required this.session, super.key});

  final FastingSession session;

  @override
  Widget build(BuildContext context) {
    final result = session.result;
    final actualDuration = session.actualDuration;
    final actualEndTime = session.actualEndTime;

    if (result == null || actualDuration == null || actualEndTime == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Latest Fasting Session', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            _SummaryRow(label: 'Result', value: _formatResult(result)),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Actual Duration',
              value: _formatDuration(actualDuration),
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Actual End Time',
              value: _formatDateAndTime(localizations, actualEndTime),
            ),
          ],
        ),
      ),
    );
  }

  String _formatResult(FastingResult result) {
    return switch (result) {
      FastingResult.completed => 'Completed',
      FastingResult.endedEarly => 'Ended Early',
    };
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours == 0) {
      return '${minutes}m';
    }

    return '${hours}h ${minutes}m';
  }

  String _formatDateAndTime(
    MaterialLocalizations localizations,
    DateTime value,
  ) {
    final localValue = value.toLocal();
    final date = localizations.formatMediumDate(localValue);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(localValue),
    );

    return '$date $time';
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: theme.textTheme.labelLarge)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
