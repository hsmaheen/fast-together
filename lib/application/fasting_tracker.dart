import 'package:fasting_app/domain/fasting_plan.dart';
import 'package:fasting_app/domain/fasting_session.dart';

enum FastingStatus { fasting, notFasting }

class DailyFastingTotal {
  const DailyFastingTotal({required this.date, required this.duration});

  final DateTime date;
  final Duration duration;

  @override
  bool operator ==(Object other) {
    return other is DailyFastingTotal &&
        other.date == date &&
        other.duration == duration;
  }

  @override
  int get hashCode => Object.hash(date, duration);
}

class FastingTracker {
  FastingTracker({DateTime Function()? nowUtc})
    : _nowUtc = nowUtc ?? (() => DateTime.now().toUtc());

  final DateTime Function() _nowUtc;
  FastingSession? _activeSession;
  final List<FastingSession> _recentEndedSessions = [];

  FastingSession? get latestSession => _activeSession ?? _latestEndedSession;

  List<FastingSession> get recentEndedSessions =>
      List.unmodifiable(_recentEndedSessions);

  FastingSession? get activeSession => _activeSession;

  List<DailyFastingTotal> dailyFastingTotals({
    DateTime Function(DateTime time)? localTimeFor,
  }) {
    final toLocalTime = localTimeFor ?? (DateTime time) => time.toLocal();
    final durationsByDate = <DateTime, Duration>{};

    for (final session in _recentEndedSessions) {
      final duration = session.actualDuration;
      final actualEndTime = session.actualEndTime;
      if (duration == null || actualEndTime == null) {
        continue;
      }

      final localEndTime = toLocalTime(actualEndTime);
      final localDate = DateTime(
        localEndTime.year,
        localEndTime.month,
        localEndTime.day,
      );
      durationsByDate[localDate] =
          (durationsByDate[localDate] ?? Duration.zero) + duration;
    }

    return [
      for (final entry in durationsByDate.entries)
        DailyFastingTotal(date: entry.key, duration: entry.value),
    ];
  }

  FastingStatus get status {
    if (activeSession != null) {
      return FastingStatus.fasting;
    }

    return FastingStatus.notFasting;
  }

  void start({required DateTime startTime, required FastingPlan plan}) {
    if (status == FastingStatus.fasting) {
      throw StateError('Cannot start while already Fasting');
    }

    _requireNotFuture(startTime, 'startTime', _nowUtc());
    _activeSession = FastingSession.start(startTime: startTime, plan: plan);
  }

  void end({required DateTime actualEndTime}) {
    final session = _activeSession;
    if (session == null || !session.isActive) {
      throw StateError('Cannot end while Not Fasting');
    }

    _requireNotFuture(actualEndTime, 'actualEndTime', _nowUtc());
    _activeSession = null;
    _recentEndedSessions.insert(0, session.end(actualEndTime: actualEndTime));
  }

  void correctActualEndTime({required DateTime actualEndTime}) {
    final session = _latestEndedSession;
    if (session == null) {
      throw StateError(
        'Cannot correct actualEndTime without a Fasting Session',
      );
    }

    _requireNotFuture(actualEndTime, 'actualEndTime', _nowUtc());
    _recentEndedSessions[0] = session.correctActualEndTime(
      actualEndTime: actualEndTime,
    );
  }

  void deleteLatestEndedSession() {
    if (_latestEndedSession == null) {
      throw StateError('Cannot delete without an ended Fasting Session');
    }

    _recentEndedSessions.removeAt(0);
  }

  void deleteEndedSession(FastingSession session) {
    if (session.isActive) {
      throw StateError('Cannot delete an active Fasting Session');
    }

    final wasDeleted = _recentEndedSessions.remove(session);
    if (!wasDeleted) {
      throw StateError('Cannot delete a Fasting Session outside history');
    }
  }

  FastingSession? get _latestEndedSession =>
      _recentEndedSessions.isEmpty ? null : _recentEndedSessions.first;
}

void _requireNotFuture(DateTime time, String name, DateTime nowUtc) {
  if (!nowUtc.isUtc) {
    throw StateError('Application clock must return a UTC DateTime');
  }

  if (time.isAfter(nowUtc)) {
    throw ArgumentError.value(time, name, 'must not be in the future');
  }
}
