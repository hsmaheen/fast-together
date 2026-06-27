import 'package:fasting_app/domain/fasting_plan.dart';
import 'package:fasting_app/domain/fasting_session.dart';

enum FastingStatus { fasting, notFasting }

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
