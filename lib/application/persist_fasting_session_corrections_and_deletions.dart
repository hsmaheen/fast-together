import 'package:fasting_app/application/app_account_session.dart';
import 'package:fasting_app/application/fasting_tracker.dart';
import 'package:fasting_app/application/personal_fasting_activity_repository.dart';
import 'package:fasting_app/domain/fasting_session.dart';
import 'package:fasting_app/domain/fasting_session_id.dart';

/// Persists ended Fasting Session corrections and deletions before exposing a
/// replacement [FastingTracker] to the caller.
final class PersistFastingSessionCorrectionsAndDeletions {
  const PersistFastingSessionCorrectionsAndDeletions(
    this._appAccountSessionProvider,
    this._repository,
  );

  final AppAccountSessionProvider _appAccountSessionProvider;
  final PersonalFastingActivityRepository _repository;

  Future<FastingSessionMutation> correctActualEndTime({
    required FastingTracker tracker,
    required FastingSessionId id,
    required DateTime actualEndTime,
  }) async {
    FastingSessionCorrectionAttempt? attemptedCorrection;
    try {
      final original = tracker.recentEndedSessions
          .where((session) => session.id == id)
          .firstOrNull;
      if (original == null) {
        throw StateError('Cannot correct a Fasting Session outside history');
      }

      final candidate = tracker.copy();
      candidate.correctEndedSession(id, actualEndTime: actualEndTime);
      final corrected = candidate.recentEndedSessions
          .where((session) => session.id == id)
          .first;
      final appAccountSession = await _requireAppAccountSession();
      attemptedCorrection = FastingSessionCorrectionAttempt(
        accountId: appAccountSession.accountId,
        previousSession: original,
        correctedSession: corrected,
      );
      final snapshot = await _repository.correctEndedSession(
        appAccountSession.accountId,
        original,
        corrected,
      );
      return PersistedFastingSessionMutation(
        tracker: tracker.withSnapshot(snapshot),
        session: corrected,
      );
    } on Object catch (error, stackTrace) {
      return _failure(
        tracker: tracker,
        error: error,
        stackTrace: stackTrace,
        attemptedCorrection: attemptedCorrection,
      );
    }
  }

  /// Reconciles a correction that may have committed before its durable write
  /// acknowledgement reached the caller.
  Future<FastingSessionMutation> retryCorrection(
    FastingSessionMutationFailure failure,
  ) async {
    final attemptedCorrection = failure.attemptedCorrection;
    if (attemptedCorrection == null) {
      return _failure(
        tracker: failure.tracker,
        error: StateError('Cannot retry a missing Fasting Session correction'),
        stackTrace: StackTrace.current,
      );
    }

    try {
      final appAccountSession = await _requireAppAccountSession();
      if (appAccountSession.accountId != attemptedCorrection.accountId) {
        throw StateError(
          'Cannot retry a Fasting Session correction for a different App Account',
        );
      }

      final snapshot = await _repository.loadSnapshot(
        attemptedCorrection.accountId,
      );
      final durableSession = _endedSessionWithId(
        snapshot,
        attemptedCorrection.previousSession.id,
      );
      if (durableSession != null &&
          _sameSession(durableSession, attemptedCorrection.correctedSession)) {
        return PersistedFastingSessionMutation(
          tracker: failure.tracker.withSnapshot(snapshot),
          session: durableSession,
        );
      }
      if (durableSession == null ||
          !_sameSession(durableSession, attemptedCorrection.previousSession)) {
        throw StateError(
          'Cannot retry a correction outside its durable prior state',
        );
      }

      final persistedSnapshot = await _repository.correctEndedSession(
        attemptedCorrection.accountId,
        attemptedCorrection.previousSession,
        attemptedCorrection.correctedSession,
      );
      return PersistedFastingSessionMutation(
        tracker: failure.tracker.withSnapshot(persistedSnapshot),
        session: attemptedCorrection.correctedSession,
      );
    } on Object catch (error, stackTrace) {
      return _failure(
        tracker: failure.tracker,
        error: error,
        stackTrace: stackTrace,
        attemptedCorrection: attemptedCorrection,
      );
    }
  }

  Future<FastingSessionMutation> deleteEndedSession({
    required FastingTracker tracker,
    required FastingSessionId id,
  }) async {
    FastingSessionDeletionAttempt? attemptedDeletion;
    try {
      final selected = tracker.recentEndedSessions
          .where((session) => session.id == id)
          .firstOrNull;
      if (selected == null) {
        throw StateError('Cannot delete a Fasting Session outside history');
      }

      final appAccountSession = await _requireAppAccountSession();
      attemptedDeletion = FastingSessionDeletionAttempt(
        accountId: appAccountSession.accountId,
        expectedSession: selected,
      );
      final snapshot = await _repository.deleteExactEndedSession(
        appAccountSession.accountId,
        selected,
      );
      return PersistedFastingSessionMutation(
        tracker: tracker.withSnapshot(snapshot),
        session: selected,
      );
    } on Object catch (error, stackTrace) {
      return _failure(
        tracker: tracker,
        error: error,
        stackTrace: stackTrace,
        attemptedDeletion: attemptedDeletion,
      );
    }
  }

  /// Reconciles a deletion that may have committed before its durable write
  /// acknowledgement reached the caller.
  Future<FastingSessionMutation> retryDeletion(
    FastingSessionMutationFailure failure,
  ) async {
    final attemptedDeletion = failure.attemptedDeletion;
    if (attemptedDeletion == null) {
      return _failure(
        tracker: failure.tracker,
        error: StateError('Cannot retry a missing Fasting Session deletion'),
        stackTrace: StackTrace.current,
      );
    }

    try {
      final appAccountSession = await _requireAppAccountSession();
      if (appAccountSession.accountId != attemptedDeletion.accountId) {
        throw StateError(
          'Cannot retry a Fasting Session deletion for a different App Account',
        );
      }

      final snapshot = await _repository.loadSnapshot(
        attemptedDeletion.accountId,
      );
      final activeSession = snapshot.activeSession;
      final durableSession =
          activeSession?.id == attemptedDeletion.expectedSession.id
          ? activeSession
          : _endedSessionWithId(snapshot, attemptedDeletion.expectedSession.id);
      if (durableSession == null) {
        return PersistedFastingSessionMutation(
          tracker: failure.tracker.withSnapshot(snapshot),
          session: attemptedDeletion.expectedSession,
        );
      }
      if (!_sameSession(durableSession, attemptedDeletion.expectedSession)) {
        throw StateError(
          'Cannot retry a deletion outside its durable prior state',
        );
      }

      final persistedSnapshot = await _repository.deleteExactEndedSession(
        attemptedDeletion.accountId,
        attemptedDeletion.expectedSession,
      );
      return PersistedFastingSessionMutation(
        tracker: failure.tracker.withSnapshot(persistedSnapshot),
        session: attemptedDeletion.expectedSession,
      );
    } on Object catch (error, stackTrace) {
      return _failure(
        tracker: failure.tracker,
        error: error,
        stackTrace: stackTrace,
        attemptedDeletion: attemptedDeletion,
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
}

sealed class FastingSessionMutation {
  const FastingSessionMutation(this.tracker);

  final FastingTracker tracker;
}

final class PersistedFastingSessionMutation extends FastingSessionMutation {
  const PersistedFastingSessionMutation({
    required FastingTracker tracker,
    required this.session,
  }) : super(tracker);

  final FastingSession session;
}

final class FastingSessionMutationFailure extends FastingSessionMutation {
  const FastingSessionMutationFailure({
    required FastingTracker tracker,
    required this.error,
    required this.stackTrace,
    this.attemptedCorrection,
    this.attemptedDeletion,
  }) : super(tracker);

  final Object error;
  final StackTrace stackTrace;
  final FastingSessionCorrectionAttempt? attemptedCorrection;
  final FastingSessionDeletionAttempt? attemptedDeletion;
}

final class FastingSessionCorrectionAttempt {
  const FastingSessionCorrectionAttempt({
    required this.accountId,
    required this.previousSession,
    required this.correctedSession,
  });

  final AppAccountId accountId;
  final FastingSession previousSession;
  final FastingSession correctedSession;
}

final class FastingSessionDeletionAttempt {
  const FastingSessionDeletionAttempt({
    required this.accountId,
    required this.expectedSession,
  });

  final AppAccountId accountId;
  final FastingSession expectedSession;
}

FastingSessionMutationFailure _failure({
  required FastingTracker tracker,
  required Object error,
  required StackTrace stackTrace,
  FastingSessionCorrectionAttempt? attemptedCorrection,
  FastingSessionDeletionAttempt? attemptedDeletion,
}) {
  return FastingSessionMutationFailure(
    tracker: tracker,
    error: error,
    stackTrace: stackTrace,
    attemptedCorrection: attemptedCorrection,
    attemptedDeletion: attemptedDeletion,
  );
}

FastingSession? _endedSessionWithId(
  PersonalFastingActivitySnapshot snapshot,
  FastingSessionId id,
) {
  return snapshot.endedSessions
      .where((session) => session.id == id)
      .firstOrNull;
}

bool _sameSession(FastingSession left, FastingSession right) {
  return left.id == right.id &&
      left.startTime == right.startTime &&
      left.targetEndTime == right.targetEndTime &&
      left.actualEndTime == right.actualEndTime;
}
