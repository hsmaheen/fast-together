import 'package:fasting_app/domain/fasting_plan.dart';
import 'package:fasting_app/domain/fasting_session.dart';

enum FastingStatus { fasting, notFasting }

class FastingTracker {
  FastingSession? _currentSession;

  FastingSession? get currentSession => _currentSession;

  FastingStatus get status {
    final session = _currentSession;
    if (session != null && session.isActive) {
      return FastingStatus.fasting;
    }

    return FastingStatus.notFasting;
  }

  void start({required DateTime startTime, required FastingPlan plan}) {
    if (status == FastingStatus.fasting) {
      throw StateError('Cannot start while already Fasting');
    }

    _currentSession = FastingSession.start(startTime: startTime, plan: plan);
  }

  void end({required DateTime actualEndTime}) {
    final session = _currentSession;
    if (session == null || !session.isActive) {
      throw StateError('Cannot end while Not Fasting');
    }

    _currentSession = session.end(actualEndTime: actualEndTime);
  }
}
