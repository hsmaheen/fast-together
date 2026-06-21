import 'package:flutter/material.dart';

class FastingTimeSummary extends StatelessWidget {
  const FastingTimeSummary({
    required this.startTime,
    required this.targetEndTime,
    required this.elapsed,
    required this.remaining,
    this.overTarget,
    super.key,
  });

  final DateTime startTime;
  final DateTime targetEndTime;
  final Duration elapsed;
  final Duration? remaining;
  final Duration? overTarget;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SummaryRow(
          label: 'Start Time',
          value: _formatTime(localizations, startTime),
        ),
        const SizedBox(height: 8),
        _SummaryRow(
          label: 'Target End Time',
          value: _formatTime(localizations, targetEndTime),
        ),
        const SizedBox(height: 8),
        _SummaryRow(
          label: 'Elapsed',
          value: _formatDuration(elapsed),
        ),
        if (remaining != null) ...[
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'Remaining',
            value: _formatDuration(remaining!),
          ),
        ] else if (overTarget != null) ...[
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'Over Target',
            value: _formatDuration(overTarget!),
          ),
        ],
      ],
    );
  }

  String _formatTime(MaterialLocalizations localizations, DateTime value) {
    final localValue = value.toLocal();

    return localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(localValue),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours == 0) {
      return '${minutes}m';
    }

    return '${hours}h ${minutes}m';
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge,
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
