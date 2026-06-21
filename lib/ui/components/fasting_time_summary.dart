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
    final showDateContext = !_isSameLocalDate(startTime, targetEndTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SummaryRow(
          label: 'Start Time',
          value: _formatTime(
            localizations,
            startTime,
            includeDate: showDateContext,
          ),
        ),
        const SizedBox(height: 8),
        _SummaryRow(
          label: 'Target End Time',
          value: _formatTime(
            localizations,
            targetEndTime,
            includeDate: showDateContext,
          ),
        ),
        const SizedBox(height: 8),
        _SummaryRow(label: 'Elapsed', value: _formatDuration(elapsed)),
        if (remaining != null) ...[
          const SizedBox(height: 8),
          _SummaryRow(label: 'Remaining', value: _formatDuration(remaining!)),
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

  bool _isSameLocalDate(DateTime first, DateTime second) {
    final firstLocal = first.toLocal();
    final secondLocal = second.toLocal();

    return firstLocal.year == secondLocal.year &&
        firstLocal.month == secondLocal.month &&
        firstLocal.day == secondLocal.day;
  }

  String _formatTime(
    MaterialLocalizations localizations,
    DateTime value, {
    required bool includeDate,
  }) {
    final localValue = value.toLocal();
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(localValue),
    );

    if (!includeDate) {
      return time;
    }

    return '${localizations.formatMediumDate(localValue)} $time';
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
