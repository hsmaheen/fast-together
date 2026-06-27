import 'package:fasting_app/application/fasting_tracker.dart';
import 'package:flutter/material.dart';

class CalendarDayFastingTotal extends StatelessWidget {
  const CalendarDayFastingTotal({
    required this.selectedDate,
    required this.dailyTotals,
    super.key,
  });

  final DateTime selectedDate;
  final List<DailyFastingTotal> dailyTotals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final total = _totalForSelectedDate;

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
            Text(
              localizations.formatMediumDate(selectedDate),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              total == null
                  ? 'No fasting total for this day yet.'
                  : _formatDuration(total.duration),
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  DailyFastingTotal? get _totalForSelectedDate {
    for (final total in dailyTotals) {
      if (_isSameCalendarDate(total.date, selectedDate)) {
        return total;
      }
    }

    return null;
  }

  bool _isSameCalendarDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
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
