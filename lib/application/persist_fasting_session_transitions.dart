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

      return await _persist(
        originalTracker: tracker,
        candidateTracker: candidate,
        session: session,
      );
    } on Object catch (error, stackTrace) {
      return FastingSessionTransitionFailure(
        tracker: tracker,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<FastingSessionTransition> end({
    required FastingTracker tracker,
    required DateTime actualEndTime,
  }) async {
    final candidate = tracker.copy();

    try {
      final FastingSession session;
      if (candidate.activeSession != null) {
        candidate.end(actualEndTime: actualEndTime);
        session = candidate.latestSession!;
      } else {
        final latestEndedSession = candidate.latestSession;
        if (latestEndedSession == null ||
            latestEndedSession.actualEndTime != actualEndTime) {
          throw StateError('Cannot end while Not Fasting');
        }
        session = latestEndedSession;
      }
      return await _persist(
        originalTracker: tracker,
        candidateTracker: candidate,
        session: session,
      );
    } on Object catch (error, stackTrace) {
      return FastingSessionTransitionFailure(
        tracker: tracker,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<FastingSessionTransition> _persist({
    required FastingTracker originalTracker,
    required FastingTracker candidateTracker,
    required FastingSession session,
  }) async {
    try {
      final appAccountSession = await _appAccountSessionProvider
          .currentSession();
      if (appAccountSession == null) {
        throw StateError(
          'Cannot persist a Fasting Session without an App Account session',
        );
      }

      final snapshot = await _repository.upsert(
        appAccountSession.accountId,
        session,
      );
      return PersistedFastingSessionTransition(
        tracker: candidateTracker.withSnapshot(snapshot),
        session: session,
      );
    } on Object catch (error, stackTrace) {
      return FastingSessionTransitionFailure(
        tracker: originalTracker,
        error: error,
        stackTrace: stackTrace,
      );
    }
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
  }) : super(tracker);

  final Object error;
  final StackTrace stackTrace;
}

bool _matchesStart(
  FastingSession session, {
  required DateTime startTime,
  required FastingPlan plan,
}) {
  return session.startTime == startTime &&
      session.targetEndTime == plan.targetEndTimeFrom(startTime);
}
