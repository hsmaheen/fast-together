import 'package:flutter/material.dart';

typedef StartTimePicker =
    Future<DateTime?> Function(
      BuildContext context,
      DateTime selectedStartTime,
    );

typedef StartDatePicker =
    Future<DateTime?> Function(
      BuildContext context,
      DateTime selectedLocalDate,
    );

typedef StartClockTimePicker =
    Future<TimeOfDay?> Function(
      BuildContext context,
      DateTime selectedLocalDateTime,
    );

class StartTimeSelector extends StatelessWidget {
  const StartTimeSelector({
    required this.selectedStartTime,
    required this.onChanged,
    this.selectStartTime,
    this.selectDate,
    this.selectClockTime,
    super.key,
  });

  final DateTime selectedStartTime;
  final ValueChanged<DateTime> onChanged;
  final StartTimePicker? selectStartTime;
  final StartDatePicker? selectDate;
  final StartClockTimePicker? selectClockTime;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Start Time', style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(
                _formatDateAndTime(localizations, selectedStartTime),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: () => _selectStartTime(context),
          child: const Text('Edit'),
        ),
      ],
    );
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final selected = await _pickStartTime(context);

    if (!context.mounted) {
      return;
    }

    if (selected != null) {
      onChanged(selected.toUtc());
    }
  }

  Future<DateTime?> _pickStartTime(BuildContext context) {
    final picker = selectStartTime;
    if (picker != null) {
      return picker(context, selectedStartTime);
    }

    return _defaultSelectStartTime(context);
  }

  Future<DateTime?> _defaultSelectStartTime(BuildContext context) async {
    final localStartTime = selectedStartTime.toLocal();

    final selectedDate = await (selectDate ?? _defaultSelectDate)(
      context,
      localStartTime,
    );

    if (!context.mounted || selectedDate == null) {
      return null;
    }

    final selectedDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      localStartTime.hour,
      localStartTime.minute,
    );
    final selectedTime = await (selectClockTime ?? _defaultSelectClockTime)(
      context,
      selectedDateTime,
    );

    if (selectedTime == null) {
      return null;
    }

    return _combineLocalDateAndTime(selectedDate, selectedTime);
  }

  Future<DateTime?> _defaultSelectDate(
    BuildContext context,
    DateTime selectedLocalDate,
  ) {
    final today = DateTime.now();

    return showDatePicker(
      context: context,
      initialDate: selectedLocalDate,
      firstDate: DateTime(today.year - 1, today.month, today.day),
      lastDate: DateTime(today.year, today.month, today.day),
    );
  }

  Future<TimeOfDay?> _defaultSelectClockTime(
    BuildContext context,
    DateTime selectedLocalDateTime,
  ) {
    return showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedLocalDateTime),
    );
  }

  DateTime _combineLocalDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    ).toUtc();
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
