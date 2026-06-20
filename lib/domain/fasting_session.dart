import 'package:fasting_app/domain/fasting_plan.dart';

enum FastingResult { completed, endedEarly }

class FastingSession {
  factory FastingSession({
    required DateTime startTime,
    required DateTime targetEndTime,
    DateTime? actualEndTime,
  }) {
    _requireUtc(startTime, 'startTime');
    _requireUtc(targetEndTime, 'targetEndTime');
    _requireUtc(actualEndTime, 'actualEndTime');
    if (actualEndTime != null && !actualEndTime.isAfter(startTime)) {
      throw ArgumentError.value(
        actualEndTime,
        'actualEndTime',
        'must be after startTime',
      );
    }

    return FastingSession._(
      startTime: startTime,
      targetEndTime: targetEndTime,
      actualEndTime: actualEndTime,
    );
  }

  const FastingSession._({
    required this.startTime,
    required this.targetEndTime,
    this.actualEndTime,
  });

  factory FastingSession.start({
    required DateTime startTime,
    required FastingPlan plan,
  }) {
    return FastingSession(
      startTime: startTime,
      targetEndTime: plan.targetEndTimeFrom(startTime),
    );
  }

  final DateTime startTime;
  final DateTime targetEndTime;
  final DateTime? actualEndTime;

  bool get isActive => actualEndTime == null;

  FastingResult? get result {
    final endTime = actualEndTime;
    if (endTime == null) {
      return null;
    }

    if (endTime.isBefore(targetEndTime)) {
      return FastingResult.endedEarly;
    }

    return FastingResult.completed;
  }

  FastingSession end({required DateTime actualEndTime}) {
    return FastingSession(
      startTime: startTime,
      targetEndTime: targetEndTime,
      actualEndTime: actualEndTime,
    );
  }

  Duration elapsedAt(DateTime time) => time.difference(startTime);

  Duration remainingAt(DateTime time) => targetEndTime.difference(time);

  Duration overTargetAt(DateTime time) => time.difference(targetEndTime);
}

void _requireUtc(DateTime? time, String name) {
  if (time != null && !time.isUtc) {
    throw ArgumentError.value(time, name, 'must be UTC');
  }
}
