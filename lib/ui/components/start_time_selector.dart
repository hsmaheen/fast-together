import 'package:flutter/material.dart';

typedef StartTimePicker = Future<DateTime?> Function(
  BuildContext context,
  DateTime selectedStartTime,
);

class StartTimeSelector extends StatelessWidget {
  const StartTimeSelector({
    required this.selectedStartTime,
    required this.onChanged,
    this.selectStartTime,
    super.key,
  });

  final DateTime selectedStartTime;
  final ValueChanged<DateTime> onChanged;
  final StartTimePicker? selectStartTime;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Start Time',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(localizations, selectedStartTime),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        TextButton(
          onPressed: () => _selectStartTime(context),
          child: const Text('Edit'),
        ),
      ],
    );
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final selected = await (selectStartTime ?? _defaultSelectStartTime)(
      context,
      selectedStartTime,
    );

    if (selected != null) {
      onChanged(selected.toUtc());
    }
  }

  Future<DateTime?> _defaultSelectStartTime(
    BuildContext context,
    DateTime selectedStartTime,
  ) async {
    final localStartTime = selectedStartTime.toLocal();
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(localStartTime),
    );

    if (selectedTime == null) {
      return null;
    }

    return DateTime(
      localStartTime.year,
      localStartTime.month,
      localStartTime.day,
      selectedTime.hour,
      selectedTime.minute,
    ).toUtc();
  }

  String _formatTime(MaterialLocalizations localizations, DateTime value) {
    final localValue = value.toLocal();

    return localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(localValue),
    );
  }
}
