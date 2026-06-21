import 'package:flutter/material.dart';

typedef ActualEndTimePicker =
    Future<DateTime?> Function(
      BuildContext context,
      DateTime selectedActualEndTime,
    );

class ActualEndTimeSelector extends StatelessWidget {
  const ActualEndTimeSelector({
    required this.selectedActualEndTime,
    required this.onChanged,
    this.selectActualEndTime,
    super.key,
  });

  final DateTime selectedActualEndTime;
  final ValueChanged<DateTime> onChanged;
  final ActualEndTimePicker? selectActualEndTime;

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
              Text('Actual End Time', style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(
                _formatDateAndTime(localizations, selectedActualEndTime),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: () => _selectActualEndTime(context),
          child: const Text('Edit'),
        ),
      ],
    );
  }

  Future<void> _selectActualEndTime(BuildContext context) async {
    final selected = await _pickActualEndTime(context);

    if (!context.mounted) {
      return;
    }

    if (selected != null) {
      onChanged(selected.toUtc());
    }
  }

  Future<DateTime?> _pickActualEndTime(BuildContext context) {
    final picker = selectActualEndTime;
    if (picker != null) {
      return picker(context, selectedActualEndTime);
    }

    return _defaultSelectActualEndTime(context);
  }

  Future<DateTime?> _defaultSelectActualEndTime(BuildContext context) async {
    final localActualEndTime = selectedActualEndTime.toLocal();
    final today = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: localActualEndTime,
      firstDate: DateTime(today.year - 1, today.month, today.day),
      lastDate: DateTime(today.year, today.month, today.day),
    );

    if (!context.mounted || selectedDate == null) {
      return null;
    }

    final selectedDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      localActualEndTime.hour,
      localActualEndTime.minute,
    );
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
    );

    if (selectedTime == null) {
      return null;
    }

    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
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
