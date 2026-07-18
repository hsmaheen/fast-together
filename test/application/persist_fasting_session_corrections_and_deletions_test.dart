import 'package:fasting_app/application/app_account_session.dart';
import 'package:fasting_app/application/fasting_tracker.dart';
import 'package:fasting_app/application/persist_fasting_session_corrections_and_deletions.dart';
import 'package:fasting_app/application/personal_fasting_activity_repository.dart';
import 'package:fasting_app/domain/fasting_session.dart';
import 'package:fasting_app/domain/fasting_session_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'persists an actual-end correction for the selected ended Fasting Session',
    () async {
      final accountId = AppAccountId('app-account');
      final original = _endedSession(
        id: 'corrected-session',
        actualEndTime: DateTime.utc(2026, 7, 19, 8),
      );
      final correctedActualEndTime = DateTime.utc(2026, 7, 19, 9);
      final repository = _InMemoryPersonalFastingActivityRepository(
        PersonalFastingActivitySnapshot(endedSessions: [original]),
      );
      final mutations = PersistFastingSessionCorrectionsAndDeletions(
        _FakeAppAccountSessionProvider(AppAccountSession(accountId)),
        repository,
      );
      final tracker = FastingTracker.fromSnapshot(
        snapshot: PersonalFastingActivitySnapshot(endedSessions: [original]),
        nowUtc: () => DateTime.utc(2026, 7, 20),
      );

      final outcome = await mutations.correctActualEndTime(
        tracker: tracker,
        id: original.id,
        actualEndTime: correctedActualEndTime,
      );

      expect(outcome, isA<PersistedFastingSessionMutation>());
      final persisted = outcome as PersistedFastingSessionMutation;
      expect(
        tracker.recentEndedSessions.single.actualEndTime,
        original.actualEndTime,
      );
      expect(persisted.session.id, original.id);
      expect(persisted.session.startTime, original.startTime);
      expect(persisted.session.targetEndTime, original.targetEndTime);
      expect(persisted.session.actualEndTime, correctedActualEndTime);
      expect(
        persisted.tracker.recentEndedSessions.single.actualEndTime,
        correctedActualEndTime,
      );
      expect(repository.snapshot.endedSessions.single.id, original.id);
      expect(
        repository.snapshot.endedSessions.single.actualEndTime,
        correctedActualEndTime,
      );
    },
  );

  test(
    'rejects a correction when the selected durable ended session is missing',
    () async {
      final accountId = AppAccountId('app-account');
      final localSession = _endedSession(
        id: 'missing-durable-session',
        actualEndTime: DateTime.utc(2026, 7, 19, 8),
      );
      final repository = _InMemoryPersonalFastingActivityRepository(
        PersonalFastingActivitySnapshot(),
      );
      final mutations = PersistFastingSessionCorrectionsAndDeletions(
        _FakeAppAccountSessionProvider(AppAccountSession(accountId)),
        repository,
      );
      final tracker = FastingTracker.fromSnapshot(
        snapshot: PersonalFastingActivitySnapshot(
          endedSessions: [localSession],
        ),
        nowUtc: () => DateTime.utc(2026, 7, 20),
      );

      final outcome = await mutations.correctActualEndTime(
        tracker: tracker,
        id: localSession.id,
        actualEndTime: DateTime.utc(2026, 7, 19, 9),
      );

      expect(outcome, isA<FastingSessionMutationFailure>());
      expect(outcome.tracker, same(tracker));
      expect(tracker.recentEndedSessions.single, localSession);
      expect(repository.snapshot.endedSessions, isEmpty);
    },
  );

  test(
    'rejects a correction when durable activity has a different prior end',
    () async {
      final accountId = AppAccountId('app-account');
      final localSession = _endedSession(
        id: 'stale-correction-session',
        actualEndTime: DateTime.utc(2026, 7, 19, 8),
      );
      final durableSession = localSession.correctActualEndTime(
        actualEndTime: DateTime.utc(2026, 7, 19, 8, 30),
      );
      final repository = _InMemoryPersonalFastingActivityRepository(
        PersonalFastingActivitySnapshot(endedSessions: [durableSession]),
      );
      final mutations = PersistFastingSessionCorrectionsAndDeletions(
        _FakeAppAccountSessionProvider(AppAccountSession(accountId)),
        repository,
      );
      final tracker = FastingTracker.fromSnapshot(
        snapshot: PersonalFastingActivitySnapshot(
          endedSessions: [localSession],
        ),
        nowUtc: () => DateTime.utc(2026, 7, 20),
      );

      final outcome = await mutations.correctActualEndTime(
        tracker: tracker,
        id: localSession.id,
        actualEndTime: DateTime.utc(2026, 7, 19, 9),
      );

      expect(outcome, isA<FastingSessionMutationFailure>());
      expect(outcome.tracker, same(tracker));
      expect(
        repository.snapshot.endedSessions.single.actualEndTime,
        durableSession.actualEndTime,
      );
    },
  );

  test(
    'rejects a correction with a future actual end time before writing',
    () async {
      final accountId = AppAccountId('app-account');
      final original = _endedSession(
        id: 'future-correction-session',
        actualEndTime: DateTime.utc(2026, 7, 19, 8),
      );
      final repository = _InMemoryPersonalFastingActivityRepository(
        PersonalFastingActivitySnapshot(endedSessions: [original]),
      );
      final mutations = PersistFastingSessionCorrectionsAndDeletions(
        _FakeAppAccountSessionProvider(AppAccountSession(accountId)),
        repository,
      );
      final tracker = FastingTracker.fromSnapshot(
        snapshot: PersonalFastingActivitySnapshot(endedSessions: [original]),
        nowUtc: () => DateTime.utc(2026, 7, 20),
      );

      final outcome = await mutations.correctActualEndTime(
        tracker: tracker,
        id: original.id,
        actualEndTime: DateTime.utc(2026, 7, 21),
      );

      expect(outcome, isA<FastingSessionMutationFailure>());
      expect(outcome.tracker, same(tracker));
      expect(
        repository.snapshot.endedSessions.single.actualEndTime,
        original.actualEndTime,
      );
    },
  );

  test(
    'deletes only the selected ended Fasting Session after durable deletion',
    () async {
      final accountId = AppAccountId('app-account');
      final selected = _endedSession(
        id: 'selected-ended-session',
        actualEndTime: DateTime.utc(2026, 7, 19, 8),
      );
      final retained = _endedSession(
        id: 'retained-ended-session',
        actualEndTime: DateTime.utc(2026, 7, 18, 8),
      );
      final snapshot = PersonalFastingActivitySnapshot(
        endedSessions: [selected, retained],
      );
      final repository = _InMemoryPersonalFastingActivityRepository(snapshot);
      final mutations = PersistFastingSessionCorrectionsAndDeletions(
        _FakeAppAccountSessionProvider(AppAccountSession(accountId)),
        repository,
      );
      final tracker = FastingTracker.fromSnapshot(
        snapshot: snapshot,
        nowUtc: () => DateTime.utc(2026, 7, 20),
      );

      final outcome = await mutations.deleteEndedSession(
        tracker: tracker,
        id: selected.id,
      );

      expect(outcome, isA<PersistedFastingSessionMutation>());
      final persisted = outcome as PersistedFastingSessionMutation;
      expect(tracker.recentEndedSessions.map((session) => session.id), [
        selected.id,
        retained.id,
      ]);
      expect(persisted.session, selected);
      expect(
        persisted.tracker.recentEndedSessions.map((session) => session.id),
        [retained.id],
      );
      expect(repository.snapshot.endedSessions.map((session) => session.id), [
        retained.id,
      ]);
    },
  );

  test(
    'rejects deletion when the selected durable session changed after hydration',
    () async {
      final accountId = AppAccountId('app-account');
      final localSession = _endedSession(
        id: 'stale-delete-session',
        actualEndTime: DateTime.utc(2026, 7, 19, 8),
      );
      final durableSession = localSession.correctActualEndTime(
        actualEndTime: DateTime.utc(2026, 7, 19, 8, 30),
      );
      final repository = _InMemoryPersonalFastingActivityRepository(
        PersonalFastingActivitySnapshot(endedSessions: [durableSession]),
      );
      final mutations = PersistFastingSessionCorrectionsAndDeletions(
        _FakeAppAccountSessionProvider(AppAccountSession(accountId)),
        repository,
      );
      final tracker = FastingTracker.fromSnapshot(
        snapshot: PersonalFastingActivitySnapshot(
          endedSessions: [localSession],
        ),
        nowUtc: () => DateTime.utc(2026, 7, 20),
      );

      final outcome = await mutations.deleteEndedSession(
        tracker: tracker,
        id: localSession.id,
      );

      expect(outcome, isA<FastingSessionMutationFailure>());
      expect(outcome.tracker, same(tracker));
      expect(
        repository.snapshot.endedSessions.single.actualEndTime,
        durableSession.actualEndTime,
      );
    },
  );

  test(
    'reconciles a correction that committed before reporting a persistence error',
    () async {
      final accountId = AppAccountId('app-account');
      final original = _endedSession(
        id: 'lost-correction-acknowledgement',
        actualEndTime: DateTime.utc(2026, 7, 19, 8),
      );
      final repository = _InMemoryPersonalFastingActivityRepository(
        PersonalFastingActivitySnapshot(endedSessions: [original]),
      )..throwAfterNextCorrection = true;
      final mutations = PersistFastingSessionCorrectionsAndDeletions(
        _FakeAppAccountSessionProvider(AppAccountSession(accountId)),
        repository,
      );
      final tracker = FastingTracker.fromSnapshot(
        snapshot: PersonalFastingActivitySnapshot(endedSessions: [original]),
        nowUtc: () => DateTime.utc(2026, 7, 20),
      );

      final firstAttempt = await mutations.correctActualEndTime(
        tracker: tracker,
        id: original.id,
        actualEndTime: DateTime.utc(2026, 7, 19, 9),
      );
      final failedCorrection = firstAttempt as FastingSessionMutationFailure;

      final reconciled = await mutations.retryCorrection(failedCorrection);

      expect(reconciled, isA<PersistedFastingSessionMutation>());
      expect(
        reconciled.tracker.recentEndedSessions.single.actualEndTime,
        DateTime.utc(2026, 7, 19, 9),
      );
      expect(repository.correctionWrites, 1);
    },
  );

  test(
    'reconciles a deletion that committed before reporting a persistence error',
    () async {
      final accountId = AppAccountId('app-account');
      final selected = _endedSession(
        id: 'lost-deletion-acknowledgement',
        actualEndTime: DateTime.utc(2026, 7, 19, 8),
      );
      final repository = _InMemoryPersonalFastingActivityRepository(
        PersonalFastingActivitySnapshot(endedSessions: [selected]),
      )..throwAfterNextDeletion = true;
      final mutations = PersistFastingSessionCorrectionsAndDeletions(
        _FakeAppAccountSessionProvider(AppAccountSession(accountId)),
        repository,
      );
      final tracker = FastingTracker.fromSnapshot(
        snapshot: PersonalFastingActivitySnapshot(endedSessions: [selected]),
        nowUtc: () => DateTime.utc(2026, 7, 20),
      );

      final firstAttempt = await mutations.deleteEndedSession(
        tracker: tracker,
        id: selected.id,
      );
      final failedDeletion = firstAttempt as FastingSessionMutationFailure;

      final reconciled = await mutations.retryDeletion(failedDeletion);

      expect(reconciled, isA<PersistedFastingSessionMutation>());
      expect(reconciled.tracker.recentEndedSessions, isEmpty);
      expect(repository.deletionWrites, 1);
    },
  );

  test(
    'rejects a lost-acknowledgement deletion retry when the ID is durable active',
    () async {
      final accountId = AppAccountId('app-account');
      final original = _endedSession(
        id: 'reused-after-deletion',
        actualEndTime: DateTime.utc(2026, 7, 19, 8),
      );
      final repository = _InMemoryPersonalFastingActivityRepository(
        PersonalFastingActivitySnapshot(endedSessions: [original]),
      )..throwAfterNextDeletion = true;
      final mutations = PersistFastingSessionCorrectionsAndDeletions(
        _FakeAppAccountSessionProvider(AppAccountSession(accountId)),
        repository,
      );
      final tracker = FastingTracker.fromSnapshot(
        snapshot: PersonalFastingActivitySnapshot(endedSessions: [original]),
        nowUtc: () => DateTime.utc(2026, 7, 20),
      );

      final firstAttempt = await mutations.deleteEndedSession(
        tracker: tracker,
        id: original.id,
      );
      final reusedActiveSession = FastingSession(
        id: original.id,
        startTime: original.startTime,
        targetEndTime: original.targetEndTime,
      );
      repository.snapshot = PersonalFastingActivitySnapshot(
        activeSession: reusedActiveSession,
      );

      final retried = await mutations.retryDeletion(
        firstAttempt as FastingSessionMutationFailure,
      );

      expect(retried, isA<FastingSessionMutationFailure>());
      expect(retried.tracker, same(tracker));
      expect(repository.snapshot.activeSession, reusedActiveSession);
      expect(repository.snapshot.endedSessions, isEmpty);
      expect(repository.deletionWrites, 1);
    },
  );

  test('rejects a correction retry after the App Account changes', () async {
    final accountA = AppAccountId('account-a');
    final accountB = AppAccountId('account-b');
    final original = _endedSession(
      id: 'account-bound-correction',
      actualEndTime: DateTime.utc(2026, 7, 19, 8),
    );
    final repository = _InMemoryPersonalFastingActivityRepository(
      PersonalFastingActivitySnapshot(endedSessions: [original]),
    )..throwAfterNextCorrection = true;
    final sessions = _SwitchableAppAccountSessionProvider(
      AppAccountSession(accountA),
    );
    final mutations = PersistFastingSessionCorrectionsAndDeletions(
      sessions,
      repository,
    );
    final tracker = FastingTracker.fromSnapshot(
      snapshot: PersonalFastingActivitySnapshot(endedSessions: [original]),
      nowUtc: () => DateTime.utc(2026, 7, 20),
    );

    final firstAttempt = await mutations.correctActualEndTime(
      tracker: tracker,
      id: original.id,
      actualEndTime: DateTime.utc(2026, 7, 19, 9),
    );
    sessions.session = AppAccountSession(accountB);

    final retried = await mutations.retryCorrection(
      firstAttempt as FastingSessionMutationFailure,
    );

    expect(retried, isA<FastingSessionMutationFailure>());
    expect(retried.tracker, same(tracker));
    expect(repository.correctionAccountIds, [accountA]);
    expect(repository.correctionWrites, 1);
  });

  test('rejects a deletion retry after the App Account changes', () async {
    final accountA = AppAccountId('account-a');
    final accountB = AppAccountId('account-b');
    final original = _endedSession(
      id: 'account-bound-deletion',
      actualEndTime: DateTime.utc(2026, 7, 19, 8),
    );
    final repository = _InMemoryPersonalFastingActivityRepository(
      PersonalFastingActivitySnapshot(endedSessions: [original]),
    )..throwAfterNextDeletion = true;
    final sessions = _SwitchableAppAccountSessionProvider(
      AppAccountSession(accountA),
    );
    final mutations = PersistFastingSessionCorrectionsAndDeletions(
      sessions,
      repository,
    );
    final tracker = FastingTracker.fromSnapshot(
      snapshot: PersonalFastingActivitySnapshot(endedSessions: [original]),
      nowUtc: () => DateTime.utc(2026, 7, 20),
    );

    final firstAttempt = await mutations.deleteEndedSession(
      tracker: tracker,
      id: original.id,
    );
    sessions.session = AppAccountSession(accountB);

    final retried = await mutations.retryDeletion(
      firstAttempt as FastingSessionMutationFailure,
    );

    expect(retried, isA<FastingSessionMutationFailure>());
    expect(retried.tracker, same(tracker));
    expect(repository.deletionAccountIds, [accountA]);
    expect(repository.deletionWrites, 1);
  });

  test(
    'rejects a repeated direct deletion after it has durably succeeded',
    () async {
      final accountId = AppAccountId('app-account');
      final original = _endedSession(
        id: 'repeated-deletion',
        actualEndTime: DateTime.utc(2026, 7, 19, 8),
      );
      final repository = _InMemoryPersonalFastingActivityRepository(
        PersonalFastingActivitySnapshot(endedSessions: [original]),
      );
      final mutations = PersistFastingSessionCorrectionsAndDeletions(
        _FakeAppAccountSessionProvider(AppAccountSession(accountId)),
        repository,
      );
      final tracker = FastingTracker.fromSnapshot(
        snapshot: PersonalFastingActivitySnapshot(endedSessions: [original]),
        nowUtc: () => DateTime.utc(2026, 7, 20),
      );

      final first = await mutations.deleteEndedSession(
        tracker: tracker,
        id: original.id,
      );
      final repeated = await mutations.deleteEndedSession(
        tracker: tracker,
        id: original.id,
      );

      expect(first, isA<PersistedFastingSessionMutation>());
      expect(repeated, isA<FastingSessionMutationFailure>());
      expect(repeated.tracker, same(tracker));
      expect(repository.deletionWrites, 1);
    },
  );

  test(
    'rejects deleting an active Fasting Session without changing local activity',
    () async {
      final accountId = AppAccountId('app-account');
      final active = FastingSession(
        id: FastingSessionId('active-session'),
        startTime: DateTime.utc(2026, 7, 19, 8),
        targetEndTime: DateTime.utc(2026, 7, 20),
      );
      final repository = _InMemoryPersonalFastingActivityRepository(
        PersonalFastingActivitySnapshot(activeSession: active),
      );
      final mutations = PersistFastingSessionCorrectionsAndDeletions(
        _FakeAppAccountSessionProvider(AppAccountSession(accountId)),
        repository,
      );
      final tracker = FastingTracker.fromSnapshot(
        snapshot: PersonalFastingActivitySnapshot(activeSession: active),
        nowUtc: () => DateTime.utc(2026, 7, 20),
      );

      final outcome = await mutations.deleteEndedSession(
        tracker: tracker,
        id: active.id,
      );

      expect(outcome, isA<FastingSessionMutationFailure>());
      expect(outcome.tracker, same(tracker));
      expect(repository.snapshot.activeSession, active);
    },
  );

  test('rejects deleting a missing durable ended Fasting Session', () async {
    final accountId = AppAccountId('app-account');
    final localSession = _endedSession(
      id: 'missing-delete-session',
      actualEndTime: DateTime.utc(2026, 7, 19, 8),
    );
    final repository = _InMemoryPersonalFastingActivityRepository(
      PersonalFastingActivitySnapshot(),
    );
    final mutations = PersistFastingSessionCorrectionsAndDeletions(
      _FakeAppAccountSessionProvider(AppAccountSession(accountId)),
      repository,
    );
    final tracker = FastingTracker.fromSnapshot(
      snapshot: PersonalFastingActivitySnapshot(endedSessions: [localSession]),
      nowUtc: () => DateTime.utc(2026, 7, 20),
    );

    final outcome = await mutations.deleteEndedSession(
      tracker: tracker,
      id: localSession.id,
    );

    expect(outcome, isA<FastingSessionMutationFailure>());
    expect(outcome.tracker, same(tracker));
    expect(repository.snapshot.endedSessions, isEmpty);
  });

  test(
    'rebuilds recent history and calendar totals from corrected then deleted activity',
    () async {
      final accountId = AppAccountId('app-account');
      final original = _endedSession(
        id: 'calendar-correction-session',
        actualEndTime: DateTime.utc(2026, 7, 19, 8),
      );
      final repository = _InMemoryPersonalFastingActivityRepository(
        PersonalFastingActivitySnapshot(endedSessions: [original]),
      );
      final mutations = PersistFastingSessionCorrectionsAndDeletions(
        _FakeAppAccountSessionProvider(AppAccountSession(accountId)),
        repository,
      );
      final tracker = FastingTracker.fromSnapshot(
        snapshot: PersonalFastingActivitySnapshot(endedSessions: [original]),
        nowUtc: () => DateTime.utc(2026, 7, 21),
      );

      final corrected =
          await mutations.correctActualEndTime(
                tracker: tracker,
                id: original.id,
                actualEndTime: DateTime.utc(2026, 7, 20, 8),
              )
              as PersistedFastingSessionMutation;
      final deleted =
          await mutations.deleteEndedSession(
                tracker: corrected.tracker,
                id: original.id,
              )
              as PersistedFastingSessionMutation;

      expect(corrected.tracker.recentEndedSessions.single.id, original.id);
      expect(
        corrected.tracker.dailyFastingTotals(localTimeFor: (time) => time),
        [
          DailyFastingTotal(
            date: DateTime(2026, 7, 20),
            duration: const Duration(hours: 40),
          ),
        ],
      );
      expect(deleted.tracker.recentEndedSessions, isEmpty);
      expect(
        deleted.tracker.dailyFastingTotals(localTimeFor: (time) => time),
        isEmpty,
      );
    },
  );
}

FastingSession _endedSession({
  required String id,
  required DateTime actualEndTime,
}) {
  return FastingSession(
    id: FastingSessionId(id),
    startTime: actualEndTime.subtract(const Duration(hours: 16)),
    targetEndTime: actualEndTime.subtract(const Duration(hours: 4)),
    actualEndTime: actualEndTime,
  );
}

final class _FakeAppAccountSessionProvider
    implements AppAccountSessionProvider {
  const _FakeAppAccountSessionProvider(this._session);

  final AppAccountSession? _session;

  @override
  Future<AppAccountSession?> currentSession() async => _session;

  @override
  Future<AppAccountSession> signInOrCreateForLocalEmulator() async {
    return _session ?? (throw StateError('No App Account session'));
  }
}

final class _SwitchableAppAccountSessionProvider
    implements AppAccountSessionProvider {
  _SwitchableAppAccountSessionProvider(this.session);

  AppAccountSession? session;

  @override
  Future<AppAccountSession?> currentSession() async => session;

  @override
  Future<AppAccountSession> signInOrCreateForLocalEmulator() async {
    return session ?? (throw StateError('No App Account session'));
  }
}

final class _InMemoryPersonalFastingActivityRepository
    implements PersonalFastingActivityRepository {
  _InMemoryPersonalFastingActivityRepository(this.snapshot);

  PersonalFastingActivitySnapshot snapshot;
  var throwAfterNextCorrection = false;
  var correctionWrites = 0;
  final correctionAccountIds = <AppAccountId>[];
  var throwAfterNextDeletion = false;
  var deletionWrites = 0;
  final deletionAccountIds = <AppAccountId>[];

  @override
  Future<PersonalFastingActivitySnapshot> loadSnapshot(
    AppAccountId accountId,
  ) async => snapshot;

  @override
  Future<PersonalFastingActivitySnapshot> upsert(
    AppAccountId accountId,
    FastingSession session,
  ) async {
    snapshot = snapshot.upsert(session);
    return snapshot;
  }

  @override
  Future<PersonalFastingActivitySnapshot> endActiveSession(
    AppAccountId accountId,
    FastingSession endedSession,
  ) => upsert(accountId, endedSession);

  @override
  Future<PersonalFastingActivitySnapshot> correctEndedSession(
    AppAccountId accountId,
    FastingSession previousSession,
    FastingSession correctedSession,
  ) async {
    final persisted = snapshot.endedSessions
        .where((session) => session.id == previousSession.id)
        .firstOrNull;
    if (persisted != previousSession) {
      throw StateError(
        'Cannot correct a Fasting Session outside durable activity',
      );
    }
    snapshot = snapshot.upsert(correctedSession);
    correctionWrites++;
    correctionAccountIds.add(accountId);
    if (throwAfterNextCorrection) {
      throwAfterNextCorrection = false;
      throw StateError('Firestore acknowledgement was lost');
    }
    return snapshot;
  }

  @override
  Future<PersonalFastingActivitySnapshot> deleteExactEndedSession(
    AppAccountId accountId,
    FastingSession expectedSession,
  ) async {
    final persisted = snapshot.endedSessions
        .where((session) => session.id == expectedSession.id)
        .firstOrNull;
    if (persisted != expectedSession) {
      throw StateError(
        'Cannot delete a Fasting Session outside durable activity',
      );
    }
    snapshot = snapshot.deleteEndedSession(expectedSession.id);
    deletionWrites++;
    deletionAccountIds.add(accountId);
    if (throwAfterNextDeletion) {
      throwAfterNextDeletion = false;
      throw StateError('Firestore acknowledgement was lost');
    }
    return snapshot;
  }

  @override
  Future<PersonalFastingActivitySnapshot> deleteEndedSession(
    AppAccountId accountId,
    FastingSessionId id,
  ) async {
    snapshot = snapshot.deleteEndedSession(id);
    return snapshot;
  }
}
