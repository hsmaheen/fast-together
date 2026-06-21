import 'package:fasting_app/domain/fasting_plan.dart';
import 'package:fasting_app/domain/fasting_session.dart';

enum FastingStatus { fasting, notFasting }

class FastingTracker {
  FastingTracker({DateTime Function()? nowUtc})
    : _nowUtc = nowUtc ?? (() => DateTime.now().toUtc());

  final DateTime Function() _nowUtc;
  FastingSession? _currentSession;

  FastingSession? get latestSession => _currentSession;

  FastingSession? get activeSession {
    final session = _currentSession;
    if (session == null || !session.isActive) {
      return null;
    }

    return session;
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
    _currentSession = FastingSession.start(startTime: startTime, plan: plan);
  }

  void end({required DateTime actualEndTime}) {
    final session = _currentSession;
    if (session == null || !session.isActive) {
      throw StateError('Cannot end while Not Fasting');
    }

    _requireNotFuture(actualEndTime, 'actualEndTime', _nowUtc());
    _currentSession = session.end(actualEndTime: actualEndTime);
  }

  void correctActualEndTime({required DateTime actualEndTime}) {
    final session = latestSession;
    if (session == null) {
      throw StateError(
        'Cannot correct actualEndTime without a Fasting Session',
      );
    }

    _requireNotFuture(actualEndTime, 'actualEndTime', _nowUtc());
    _currentSession = session.correctActualEndTime(
      actualEndTime: actualEndTime,
    );
  }

  void deleteLatestEndedSession() {
    final session = latestSession;
    if (session == null || session.isActive) {
      throw StateError('Cannot delete without an ended Fasting Session');
    }

    _currentSession = null;
  }
}

void _requireNotFuture(DateTime time, String name, DateTime nowUtc) {
  if (!nowUtc.isUtc) {
    throw StateError('Application clock must return a UTC DateTime');
  }

  if (time.isAfter(nowUtc)) {
    throw ArgumentError.value(time, name, 'must not be in the future');
  }
}
