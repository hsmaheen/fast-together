import 'dart:async';

import 'package:fasting_app/application/fasting_tracker.dart';
import 'package:fasting_app/domain/fasting_plan.dart';
import 'package:fasting_app/ui/components/active_fasting_status.dart';
import 'package:fasting_app/ui/components/fasting_plan_selector.dart';
import 'package:fasting_app/ui/components/start_fast_button.dart';
import 'package:fasting_app/ui/components/start_time_selector.dart';
import 'package:flutter/material.dart';

class LocalFastingStatusSection extends StatefulWidget {
  const LocalFastingStatusSection({
    required this.nowUtc,
    this.selectStartTime,
    this.tracker,
    super.key,
  });

  final DateTime Function() nowUtc;
  final StartTimePicker? selectStartTime;
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
    _selectedStartTime ??= widget.nowUtc();

    if (activeSession != null) {
      return ActiveFastingStatus(
        session: activeSession,
        currentTime: widget.nowUtc(),
        onEndPressed: () {
          setState(() {
            _tracker.end(actualEndTime: widget.nowUtc());
            _selectedStartTime = widget.nowUtc();
          });
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Not Fasting',
          style: Theme.of(context).textTheme.titleLarge,
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
              } on ArgumentError {
                _errorMessage = 'Start time cannot be in the future';
              }
            });
          },
        ),
      ],
    );
  }
}
