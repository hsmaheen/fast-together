import 'package:fasting_app/domain/fasting_plan.dart';

enum FastingResult { completed, endedEarly }

class FastingSession {
  const FastingSession({
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

  Duration elapsedAt(DateTime time) => time.difference(startTime);

  Duration remainingAt(DateTime time) => targetEndTime.difference(time);

  Duration overTargetAt(DateTime time) => time.difference(targetEndTime);
}
