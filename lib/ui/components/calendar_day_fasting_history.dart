import 'package:fasting_app/application/fasting_tracker.dart';
import 'package:fasting_app/ui/components/calendar_day_fasting_total.dart';
import 'package:flutter/material.dart';

class CalendarDayFastingHistory extends StatefulWidget {
  const CalendarDayFastingHistory({
    required this.today,
    required this.dailyTotals,
    super.key,
  });

  final DateTime today;
  final List<DailyFastingTotal> dailyTotals;

  @override
  State<CalendarDayFastingHistory> createState() =>
      _CalendarDayFastingHistoryState();
}

class _CalendarDayFastingHistoryState extends State<CalendarDayFastingHistory> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(widget.today);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final dates = _selectableDates;

    return Column(
      key: const ValueKey('calendarDayFastingHistory'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Calendar-day fasting total', style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final date in dates)
              ChoiceChip(
                label: Text(localizations.formatShortDate(date)),
                selected: _isSameCalendarDate(date, _selectedDate),
                onSelected: (_) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        CalendarDayFastingTotal(
          selectedDate: _selectedDate,
          dailyTotals: widget.dailyTotals,
        ),
      ],
    );
  }

  List<DateTime> get _selectableDates {
    final dates = <DateTime>{};
    final today = _dateOnly(widget.today);

    for (var offset = 0; offset < 7; offset += 1) {
      dates.add(today.subtract(Duration(days: offset)));
    }

    for (final total in widget.dailyTotals) {
      dates.add(_dateOnly(total.date));
    }

    return dates.toList()..sort((left, right) => right.compareTo(left));
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameCalendarDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}
