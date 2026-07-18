import 'package:fasting_app/application/app_account_session.dart';
import 'package:fasting_app/application/fasting_tracker.dart';
import 'package:fasting_app/application/personal_fasting_activity_repository.dart';
import 'package:fasting_app/domain/fasting_plan.dart';
import 'package:fasting_app/domain/fasting_session.dart';

/// Persists Fasting Session start and end transitions before exposing their
/// replacement FastingTracker to the caller.
final class PersistFastingSessionTransitions {
  const PersistFastingSessionTransitions(
    this._appAccountSessionProvider,
    this._repository,
  );

  final AppAccountSessionProvider _appAccountSessionProvider;
  final PersonalFastingActivityRepository _repository;

  Future<FastingSessionTransition> start({
    required FastingTracker tracker,
    required DateTime startTime,
    required FastingPlan plan,
  }) async {
    final candidate = tracker.copy();
    FastingSession? attemptedSession;

    try {
      final existingActiveSession = candidate.activeSession;
      final FastingSession session;
      if (existingActiveSession == null) {
        candidate.start(startTime: startTime, plan: plan);
        session = candidate.activeSession!;
      } else if (_matchesStart(
        existingActiveSession,
        startTime: startTime,
        plan: plan,
      )) {
        session = existingActiveSession;
      } else {
        throw StateError('Cannot start while already Fasting');
      }
      attemptedSession = session;

      return await _upsert(
        originalTracker: tracker,
        candidateTracker: candidate,
        session: session,
        attemptedSession: session,
      );
    } on Object catch (error, stackTrace) {
      return _failure(
        tracker: tracker,
        error: error,
        stackTrace: stackTrace,
        attemptedSession: attemptedSession,
      );
    }
  }

  /// Reconciles a failed active-session start before replaying its exact
  /// stable-ID command. The first write may have committed even though the
  /// client did not receive its acknowledgement.
  Future<FastingSessionTransition> retryStart(
    FastingSessionTransitionFailure failure,
  ) async {
    final attemptedSession = failure.attemptedSession;
    if (attemptedSession == null || !attemptedSession.isActive) {
      return _failure(
        tracker: failure.tracker,
        error: StateError('Cannot retry a start without an active session'),
        stackTrace: StackTrace.current,
      );
    }

    try {
      final appAccountSession = await _requireAppAccountSession();
      final snapshot = await _repository.loadSnapshot(
        appAccountSession.accountId,
      );
      final durableActiveSession = snapshot.activeSession;
      if (durableActiveSession != null) {
        if (!_sameSession(durableActiveSession, attemptedSession)) {
          throw StateError(
            'Cannot retry a start while another Fasting Session is active',
          );
        }

        return PersistedFastingSessionTransition(
          tracker: failure.tracker.withSnapshot(snapshot),
          session: durableActiveSession,
        );
      }

      if (snapshot.endedSessions.any(
        (session) => session.id == attemptedSession.id,
      )) {
        throw StateError('Cannot retry a start for an ended Fasting Session');
      }

      final persistedSnapshot = await _repository.upsert(
        appAccountSession.accountId,
        attemptedSession,
      );
      return PersistedFastingSessionTransition(
        tracker: failure.tracker.withSnapshot(persistedSnapshot),
        session: attemptedSession,
      );
    } on Object catch (error, stackTrace) {
      return _failure(
        tracker: failure.tracker,
        error: error,
        stackTrace: stackTrace,
        attemptedSession: attemptedSession,
      );
    }
  }

  Future<FastingSessionTransition> end({
    required FastingTracker tracker,
    required DateTime actualEndTime,
  }) async {
    try {
      final appAccountSession = await _requireAppAccountSession();
      final snapshot = await _repository.loadSnapshot(
        appAccountSession.accountId,
      );
      final durableActiveSession = snapshot.activeSession;
      final localActiveSession = tracker.activeSession;

      if (durableActiveSession == null) {
        return _reconcileEndedRetry(
          tracker: tracker,
          snapshot: snapshot,
          actualEndTime: actualEndTime,
        );
      }

      if (localActiveSession == null ||
          !_sameSession(localActiveSession, durableActiveSession)) {
        throw StateError(
          'Cannot end a Fasting Session that is not the durable active session',
        );
      }

      final candidate = tracker.withSnapshot(snapshot);
      candidate.end(actualEndTime: actualEndTime);
      final endedSession = candidate.latestSession!;
      final persistedSnapshot = await _repository.endActiveSession(
        appAccountSession.accountId,
        endedSession,
      );
      return PersistedFastingSessionTransition(
        tracker: tracker.withSnapshot(persistedSnapshot),
        session: endedSession,
      );
    } on Object catch (error, stackTrace) {
      return _failure(tracker: tracker, error: error, stackTrace: stackTrace);
    }
  }

  Future<FastingSessionTransition> _upsert({
    required FastingTracker originalTracker,
    required FastingTracker candidateTracker,
    required FastingSession session,
    FastingSession? attemptedSession,
  }) async {
    try {
      final appAccountSession = await _requireAppAccountSession();

      final snapshot = await _repository.upsert(
        appAccountSession.accountId,
        session,
      );
      return PersistedFastingSessionTransition(
        tracker: candidateTracker.withSnapshot(snapshot),
        session: session,
      );
    } on Object catch (error, stackTrace) {
      return _failure(
        tracker: originalTracker,
        error: error,
        stackTrace: stackTrace,
        attemptedSession: attemptedSession,
      );
    }
  }

  Future<AppAccountSession> _requireAppAccountSession() async {
    final appAccountSession = await _appAccountSessionProvider.currentSession();
    if (appAccountSession == null) {
      throw StateError(
        'Cannot persist a Fasting Session without an App Account session',
      );
    }

    return appAccountSession;
  }

  FastingSessionTransition _reconcileEndedRetry({
    required FastingTracker tracker,
    required PersonalFastingActivitySnapshot snapshot,
    required DateTime actualEndTime,
  }) {
    final localSession = tracker.activeSession ?? tracker.latestSession;
    if (localSession == null) {
      throw StateError('Cannot end while Not Fasting');
    }

    final durableEndedSession = snapshot.endedSessions
        .where((session) => session.id == localSession.id)
        .firstOrNull;
    if (durableEndedSession == null ||
        !_sameLifecycle(localSession, durableEndedSession) ||
        durableEndedSession.actualEndTime != actualEndTime) {
      throw StateError(
        'Cannot correct or end a Fasting Session outside durable activity',
      );
    }

    return PersistedFastingSessionTransition(
      tracker: tracker.withSnapshot(snapshot),
      session: durableEndedSession,
    );
  }
}

sealed class FastingSessionTransition {
  const FastingSessionTransition(this.tracker);

  final FastingTracker tracker;
}

final class PersistedFastingSessionTransition extends FastingSessionTransition {
  const PersistedFastingSessionTransition({
    required FastingTracker tracker,
    required this.session,
  }) : super(tracker);

  final FastingSession session;
}

final class FastingSessionTransitionFailure extends FastingSessionTransition {
  const FastingSessionTransitionFailure({
    required FastingTracker tracker,
    required this.error,
    required this.stackTrace,
    this.attemptedSession,
  }) : super(tracker);

  final Object error;
  final StackTrace stackTrace;
  final FastingSession? attemptedSession;
}

FastingSessionTransitionFailure _failure({
  required FastingTracker tracker,
  required Object error,
  required StackTrace stackTrace,
  FastingSession? attemptedSession,
}) {
  return FastingSessionTransitionFailure(
    tracker: tracker,
    error: error,
    stackTrace: stackTrace,
    attemptedSession: attemptedSession,
  );
}

bool _matchesStart(
  FastingSession session, {
  required DateTime startTime,
  required FastingPlan plan,
}) {
  return session.startTime == startTime &&
      session.targetEndTime == plan.targetEndTimeFrom(startTime);
}

bool _sameSession(FastingSession left, FastingSession right) {
  return _sameLifecycle(left, right) &&
      left.actualEndTime == right.actualEndTime;
}

bool _sameLifecycle(FastingSession left, FastingSession right) {
  return left.id == right.id &&
      left.startTime == right.startTime &&
      left.targetEndTime == right.targetEndTime;
}
