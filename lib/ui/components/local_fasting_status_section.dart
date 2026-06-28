import 'dart:async';

import 'package:fasting_app/application/fasting_tracker.dart';
import 'package:fasting_app/domain/fasting_plan.dart';
import 'package:fasting_app/domain/fasting_session.dart';
import 'package:fasting_app/ui/components/actual_end_time_selector.dart';
import 'package:fasting_app/ui/components/active_fasting_status.dart';
import 'package:fasting_app/ui/components/calendar_day_fasting_history.dart';
import 'package:fasting_app/ui/components/fasting_plan_selector.dart';
import 'package:fasting_app/ui/components/recent_fasting_sessions_list.dart';
import 'package:fasting_app/ui/components/start_fast_button.dart';
import 'package:fasting_app/ui/components/start_time_selector.dart';
import 'package:flutter/material.dart';

class LocalFastingStatusSection extends StatefulWidget {
  const LocalFastingStatusSection({
    required this.nowUtc,
    this.selectStartTime,
    this.selectActualEndTime,
    this.tracker,
    super.key,
  });

  final DateTime Function() nowUtc;
  final StartTimePicker? selectStartTime;
  final ActualEndTimePicker? selectActualEndTime;
  final FastingTracker? tracker;

  @override
  State<LocalFastingStatusSection> createState() =>
      _LocalFastingStatusSectionState();
}

class _LocalFastingStatusSectionState extends State<LocalFastingStatusSection> {
  FastingPlan _selectedPlan = FastingPlan.sixteenHours;
  DateTime? _selectedStartTime;
  late final FastingTracker _tracker;
  late final Timer _statusTicker;
  String? _errorMessage;
  String? _latestSessionErrorMessage;

  @override
  void initState() {
    super.initState();
    _tracker = widget.tracker ?? FastingTracker(nowUtc: widget.nowUtc);
    _statusTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && _tracker.activeSession != null) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _statusTicker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeSession = _tracker.activeSession;
    final recentEndedSessions = _tracker.recentEndedSessions;
    _selectedStartTime ??= widget.nowUtc();

    if (activeSession != null) {
      return ActiveFastingStatus(
        session: activeSession,
        currentTime: widget.nowUtc(),
        onEndPressed: () => _showEndFastingSessionSheet(activeSession),
        errorMessage: _errorMessage,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'Not Fasting',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton(
              key: const ValueKey('dailyFastingTotalsButton'),
              onPressed: _showCalendarDayFastingHistory,
              child: const Text('Daily totals'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FastingPlanSelector(
          selectedPlan: _selectedPlan,
          onChanged: (plan) {
            setState(() {
              _selectedPlan = plan;
            });
          },
        ),
        const SizedBox(height: 20),
        StartTimeSelector(
          selectedStartTime: _selectedStartTime!,
          onChanged: (startTime) {
            setState(() {
              _selectedStartTime = startTime;
            });
          },
          selectStartTime: widget.selectStartTime,
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 20),
        StartFastButton(
          selectedPlan: _selectedPlan,
          onPressed: () {
            setState(() {
              try {
                _tracker.start(
                  startTime: _selectedStartTime!,
                  plan: _selectedPlan,
                );
                _errorMessage = null;
                _latestSessionErrorMessage = null;
              } on ArgumentError {
                _errorMessage = 'Start time cannot be in the future';
              }
            });
          },
        ),
        const SizedBox(height: 20),
        RecentFastingSessionsList(
          sessions: recentEndedSessions,
          onLatestDeletePressed: () {
            setState(() {
              _tracker.deleteLatestEndedSession();
              _latestSessionErrorMessage = null;
            });
          },
          onSessionDeletePressed: (session) {
            setState(() {
              _tracker.deleteEndedSession(session);
              _latestSessionErrorMessage = null;
            });
          },
          onLatestActualEndTimeChanged: (actualEndTime) {
            setState(() {
              final latestSession = _tracker.latestSession;
              if (latestSession == null || latestSession.isActive) {
                return;
              }

              if (!actualEndTime.isAfter(latestSession.startTime)) {
                _latestSessionErrorMessage =
                    'Actual end time must be after the start time';
                return;
              }

              try {
                _tracker.correctActualEndTime(actualEndTime: actualEndTime);
                _latestSessionErrorMessage = null;
              } on ArgumentError {
                _latestSessionErrorMessage =
                    'Actual end time cannot be in the future';
              }
            });
          },
          latestSessionErrorMessage: _latestSessionErrorMessage,
          selectActualEndTime: widget.selectActualEndTime,
        ),
      ],
    );
  }

  Future<void> _showCalendarDayFastingHistory() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: CalendarDayFastingHistory(
            today: widget.nowUtc().toLocal(),
            dailyTotals: _tracker.dailyFastingTotals(),
          ),
        ),
      ),
    );
  }

  Future<void> _showEndFastingSessionSheet(FastingSession session) async {
    final selectedActualEndTime = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EndFastingSessionSheet(
        session: session,
        initialActualEndTime: widget.nowUtc(),
        selectActualEndTime: widget.selectActualEndTime,
      ),
    );

    if (!mounted || selectedActualEndTime == null) {
      return;
    }

    setState(() {
      if (!selectedActualEndTime.isAfter(session.startTime)) {
        _errorMessage = 'Actual end time must be after the start time';
        return;
      }

      try {
        _tracker.end(actualEndTime: selectedActualEndTime);
        _selectedStartTime = widget.nowUtc();
        _errorMessage = null;
      } on ArgumentError {
        _errorMessage = 'Actual end time cannot be in the future';
      }
    });
  }
}

class _EndFastingSessionSheet extends StatefulWidget {
  const _EndFastingSessionSheet({
    required this.session,
    required this.initialActualEndTime,
    this.selectActualEndTime,
  });

  final FastingSession session;
  final DateTime initialActualEndTime;
  final ActualEndTimePicker? selectActualEndTime;

  @override
  State<_EndFastingSessionSheet> createState() =>
      _EndFastingSessionSheetState();
}

class _EndFastingSessionSheetState extends State<_EndFastingSessionSheet> {
  late DateTime _selectedActualEndTime;

  @override
  void initState() {
    super.initState();
    _selectedActualEndTime = widget.initialActualEndTime;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = _previewFor(_selectedActualEndTime);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          key: const ValueKey('endFastingSessionSheet'),
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('End Fasting Session?', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            ActualEndTimeSelector(
              selectedActualEndTime: _selectedActualEndTime,
              onChanged: (actualEndTime) {
                setState(() {
                  _selectedActualEndTime = actualEndTime;
                });
              },
              selectActualEndTime: widget.selectActualEndTime,
            ),
            const SizedBox(height: 16),
            _PreviewRow(
              label: 'Total Fasting Time',
              value: preview == null
                  ? 'Select a time after the start time'
                  : _formatDuration(preview.actualDuration!),
            ),
            const SizedBox(height: 8),
            _PreviewRow(
              label: 'Fasting Result',
              value: preview == null
                  ? 'Unavailable'
                  : _formatResult(preview.result!),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Keep fasting'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  key: const ValueKey('confirmEndFastingSessionButton'),
                  onPressed: () =>
                      Navigator.of(context).pop(_selectedActualEndTime),
                  child: const Text('End fast'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  FastingSession? _previewFor(DateTime actualEndTime) {
    if (!actualEndTime.isAfter(widget.session.startTime)) {
      return null;
    }

    return widget.session.end(actualEndTime: actualEndTime);
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
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

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
