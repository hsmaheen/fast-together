import 'package:fasting_app/application/app_account_session.dart';
import 'package:fasting_app/application/fasting_tracker.dart';
import 'package:fasting_app/application/persist_fasting_session_transitions.dart';
import 'package:fasting_app/application/personal_fasting_activity_repository.dart';
import 'package:fasting_app/domain/fasting_plan.dart';
import 'package:fasting_app/domain/fasting_session.dart';
import 'package:fasting_app/domain/fasting_session_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts a Fasting Session after it is durably persisted', () async {
    final accountId = AppAccountId('app-account');
    final repository = _InMemoryPersonalFastingActivityRepository();
    final transitions = PersistFastingSessionTransitions(
      _FakeAppAccountSessionProvider(AppAccountSession(accountId)),
      repository,
    );
    final tracker = FastingTracker(
      nowUtc: () => DateTime.utc(2026, 7, 18, 12),
      newSessionId: () => FastingSessionId('stable-session-id'),
    );
    final startTime = DateTime.utc(2026, 7, 18, 8);

    final outcome = await transitions.start(
      tracker: tracker,
      startTime: startTime,
      plan: FastingPlan.sixteenHours,
    );

    expect(outcome, isA<PersistedFastingSessionTransition>());
    final persisted = outcome as PersistedFastingSessionTransition;
    expect(tracker.status, FastingStatus.notFasting);
    expect(persisted.tracker.status, FastingStatus.fasting);
    expect(persisted.tracker.activeSession?.id.value, 'stable-session-id');
    expect(persisted.tracker.activeSession?.startTime, startTime);
    expect(repository.upsertedSessions.single.id.value, 'stable-session-id');
    expect(repository.upsertedAccountIds.single, accountId);
  });

  test(
    'ends the persisted active Fasting Session under its stable ID',
    () async {
      final accountId = AppAccountId('app-account');
      final repository = _InMemoryPersonalFastingActivityRepository();
      final transitions = PersistFastingSessionTransitions(
        _FakeAppAccountSessionProvider(AppAccountSession(accountId)),
        repository,
      );
      final startingTracker = FastingTracker(
        nowUtc: () => DateTime.utc(2026, 7, 20),
        newSessionId: () => FastingSessionId('stable-session-id'),
      );
      final started =
          await transitions.start(
                tracker: startingTracker,
                startTime: DateTime.utc(2026, 7, 18, 8),
                plan: FastingPlan.sixteenHours,
              )
              as PersistedFastingSessionTransition;

      final outcome = await transitions.end(
        tracker: started.tracker,
        actualEndTime: DateTime.utc(2026, 7, 19, 8),
      );

      expect(outcome, isA<PersistedFastingSessionTransition>());
      final persisted = outcome as PersistedFastingSessionTransition;
      expect(persisted.session.id.value, 'stable-session-id');
      expect(persisted.session.actualEndTime, DateTime.utc(2026, 7, 19, 8));
      expect(persisted.tracker.activeSession, isNull);
      expect(
        persisted.tracker.recentEndedSessions.single.id.value,
        'stable-session-id',
      );
      expect(repository.upsertedSessions, hasLength(2));
      expect(repository.upsertedSessions.last.id.value, 'stable-session-id');
      expect(
        repository.upsertedSessions.last.actualEndTime,
        DateTime.utc(2026, 7, 19, 8),
      );
    },
  );

  test('repeats the same start as an idempotent durable upsert', () async {
    final repository = _InMemoryPersonalFastingActivityRepository();
    final transitions = PersistFastingSessionTransitions(
      _FakeAppAccountSessionProvider(
        AppAccountSession(AppAccountId('app-account')),
      ),
      repository,
    );
    final startTime = DateTime.utc(2026, 7, 18, 8);
    final plan = FastingPlan.sixteenHours;
    final started =
        await transitions.start(
              tracker: FastingTracker(
                nowUtc: () => DateTime.utc(2026, 7, 20),
                newSessionId: () => FastingSessionId('stable-session-id'),
              ),
              startTime: startTime,
              plan: plan,
            )
            as PersistedFastingSessionTransition;

    final repeated = await transitions.start(
      tracker: started.tracker,
      startTime: startTime,
      plan: plan,
    );

    expect(repeated, isA<PersistedFastingSessionTransition>());
    expect(repeated.tracker.activeSession?.id.value, 'stable-session-id');
    expect(repository.upsertedSessions, hasLength(2));
    expect(repository.upsertedSessions.map((session) => session.id.value), [
      'stable-session-id',
      'stable-session-id',
    ]);
  });

  test('repeats the same end by reconciling durable ended activity', () async {
    final repository = _InMemoryPersonalFastingActivityRepository();
    final transitions = PersistFastingSessionTransitions(
      _FakeAppAccountSessionProvider(
        AppAccountSession(AppAccountId('app-account')),
      ),
      repository,
    );
    final actualEndTime = DateTime.utc(2026, 7, 19, 8);
    final started =
        await transitions.start(
              tracker: FastingTracker(
                nowUtc: () => DateTime.utc(2026, 7, 20),
                newSessionId: () => FastingSessionId('stable-session-id'),
              ),
              startTime: DateTime.utc(2026, 7, 18, 8),
              plan: FastingPlan.sixteenHours,
            )
            as PersistedFastingSessionTransition;
    final ended =
        await transitions.end(
              tracker: started.tracker,
              actualEndTime: actualEndTime,
            )
            as PersistedFastingSessionTransition;

    final repeated = await transitions.end(
      tracker: ended.tracker,
      actualEndTime: actualEndTime,
    );

    expect(repeated, isA<PersistedFastingSessionTransition>());
    expect(repeated.tracker.activeSession, isNull);
    expect(
      repeated.tracker.recentEndedSessions.single.id.value,
      'stable-session-id',
    );
    expect(repository.upsertedSessions, hasLength(2));
    expect(repository.upsertedSessions.last.actualEndTime, actualEndTime);
  });

  test(
    'rejects a second active start without changing local or persisted activity',
    () async {
      final repository = _InMemoryPersonalFastingActivityRepository();
      final transitions = PersistFastingSessionTransitions(
        _FakeAppAccountSessionProvider(
          AppAccountSession(AppAccountId('app-account')),
        ),
        repository,
      );
      final started =
          await transitions.start(
                tracker: FastingTracker(
                  nowUtc: () => DateTime.utc(2026, 7, 20),
                  newSessionId: () => FastingSessionId('stable-session-id'),
                ),
                startTime: DateTime.utc(2026, 7, 18, 8),
                plan: FastingPlan.sixteenHours,
              )
              as PersistedFastingSessionTransition;

      final outcome = await transitions.start(
        tracker: started.tracker,
        startTime: DateTime.utc(2026, 7, 18, 9),
        plan: FastingPlan.twelveHours,
      );

      expect(outcome, isA<FastingSessionTransitionFailure>());
      expect(outcome.tracker, same(started.tracker));
      expect(outcome.tracker.activeSession?.id.value, 'stable-session-id');
      expect(repository.upsertedSessions, hasLength(1));
      expect(repository.snapshot.activeSession?.id.value, 'stable-session-id');
    },
  );

  test(
    'keeps a stale local tracker unchanged when persisted activity has another active session',
    () async {
      final existingActiveSession = FastingSession(
        id: FastingSessionId('persisted-active-session'),
        startTime: DateTime.utc(2026, 7, 18, 7),
        targetEndTime: DateTime.utc(2026, 7, 19, 7),
      );
      final repository = _InMemoryPersonalFastingActivityRepository(
        PersonalFastingActivitySnapshot(activeSession: existingActiveSession),
      );
      final tracker = FastingTracker(
        nowUtc: () => DateTime.utc(2026, 7, 20),
        newSessionId: () => FastingSessionId('new-local-session'),
      );
      final transitions = PersistFastingSessionTransitions(
        _FakeAppAccountSessionProvider(
          AppAccountSession(AppAccountId('app-account')),
        ),
        repository,
      );

      final outcome = await transitions.start(
        tracker: tracker,
        startTime: DateTime.utc(2026, 7, 18, 8),
        plan: FastingPlan.sixteenHours,
      );

      expect(outcome, isA<FastingSessionTransitionFailure>());
      expect(outcome.tracker, same(tracker));
      expect(tracker.status, FastingStatus.notFasting);
      expect(repository.snapshot.activeSession?.id, existingActiveSession.id);
    },
  );

  test(
    'reports a persistence failure without updating local tracker state',
    () async {
      final tracker = FastingTracker(
        nowUtc: () => DateTime.utc(2026, 7, 20),
        newSessionId: () => FastingSessionId('stable-session-id'),
      );
      final transitions = PersistFastingSessionTransitions(
        _FakeAppAccountSessionProvider(
          AppAccountSession(AppAccountId('app-account')),
        ),
        const _FailingPersonalFastingActivityRepository(),
      );

      final outcome = await transitions.start(
        tracker: tracker,
        startTime: DateTime.utc(2026, 7, 18, 8),
        plan: FastingPlan.sixteenHours,
      );

      expect(outcome, isA<FastingSessionTransitionFailure>());
      final failure = outcome as FastingSessionTransitionFailure;
      expect(failure.error, isA<StateError>());
      expect(failure.tracker, same(tracker));
      expect(tracker.status, FastingStatus.notFasting);
      expect(tracker.activeSession, isNull);
    },
  );

  test(
    'reports an end persistence failure without ending local tracker state',
    () async {
      final repository = _InMemoryPersonalFastingActivityRepository();
      final transitions = PersistFastingSessionTransitions(
        _FakeAppAccountSessionProvider(
          AppAccountSession(AppAccountId('app-account')),
        ),
        repository,
      );
      final started =
          await transitions.start(
                tracker: FastingTracker(
                  nowUtc: () => DateTime.utc(2026, 7, 20),
                  newSessionId: () => FastingSessionId('stable-session-id'),
                ),
                startTime: DateTime.utc(2026, 7, 18, 8),
                plan: FastingPlan.sixteenHours,
              )
              as PersistedFastingSessionTransition;
      repository.failEndedUpserts = true;

      final outcome = await transitions.end(
        tracker: started.tracker,
        actualEndTime: DateTime.utc(2026, 7, 19, 8),
      );

      expect(outcome, isA<FastingSessionTransitionFailure>());
      expect(outcome.tracker, same(started.tracker));
      expect(outcome.tracker.status, FastingStatus.fasting);
      expect(outcome.tracker.activeSession?.id.value, 'stable-session-id');
      expect(repository.snapshot.activeSession?.id.value, 'stable-session-id');
    },
  );

  test(
    'reconciles a start that committed before reporting a persistence error',
    () async {
      final repository = _CommitThenThrowPersonalFastingActivityRepository();
      final transitions = PersistFastingSessionTransitions(
        _FakeAppAccountSessionProvider(
          AppAccountSession(AppAccountId('account-a')),
        ),
        repository,
      );

      final firstAttempt = await transitions.start(
        tracker: FastingTracker(
          nowUtc: () => DateTime.utc(2026, 7, 20),
          newSessionId: () => FastingSessionId('stable-session-id'),
        ),
        startTime: DateTime.utc(2026, 7, 18, 8),
        plan: FastingPlan.sixteenHours,
      );

      expect(firstAttempt, isA<FastingSessionTransitionFailure>());
      final failedStart = firstAttempt as FastingSessionTransitionFailure;
      expect(failedStart.attemptedSession?.id.value, 'stable-session-id');
      expect(failedStart.attemptedAccountId, AppAccountId('account-a'));
      expect(failedStart.tracker.status, FastingStatus.notFasting);

      final reconciled = await transitions.retryStart(failedStart);

      expect(reconciled, isA<PersistedFastingSessionTransition>());
      expect(reconciled.tracker.activeSession?.id.value, 'stable-session-id');
      expect(repository.upsertedSessions, hasLength(1));
    },
  );

  test('rejects a failed start retry after the App Account changes', () async {
    final accountA = AppAccountId('account-a');
    final accountB = AppAccountId('account-b');
    final appAccountSessions = _SwitchableAppAccountSessionProvider(
      AppAccountSession(accountA),
    );
    final repository = _AccountScopedCommitThenThrowRepository();
    final transitions = PersistFastingSessionTransitions(
      appAccountSessions,
      repository,
    );
    final tracker = FastingTracker(
      nowUtc: () => DateTime.utc(2026, 7, 20),
      newSessionId: () => FastingSessionId('stable-session-id'),
    );

    final firstAttempt = await transitions.start(
      tracker: tracker,
      startTime: DateTime.utc(2026, 7, 18, 8),
      plan: FastingPlan.sixteenHours,
    );
    final failedStart = firstAttempt as FastingSessionTransitionFailure;
    appAccountSessions.session = AppAccountSession(accountB);

    final retried = await transitions.retryStart(failedStart);

    expect(retried, isA<FastingSessionTransitionFailure>());
    expect(retried.tracker, same(tracker));
    expect(tracker.status, FastingStatus.notFasting);
    expect(
      repository.snapshotFor(accountA).activeSession?.id.value,
      'stable-session-id',
    );
    expect(repository.snapshotFor(accountB).activeSession, isNull);
    expect(repository.upsertsFor(accountA), hasLength(1));
    expect(repository.upsertsFor(accountB), isEmpty);
  });

  test(
    'rejects ending a stale local active session when durable activity has another active session',
    () async {
      final localActive = FastingSession(
        id: FastingSessionId('local-active'),
        startTime: DateTime.utc(2026, 7, 18, 8),
        targetEndTime: DateTime.utc(2026, 7, 19, 0),
      );
      final durableActive = FastingSession(
        id: FastingSessionId('durable-active'),
        startTime: DateTime.utc(2026, 7, 18, 9),
        targetEndTime: DateTime.utc(2026, 7, 19, 1),
      );
      final repository = _InMemoryPersonalFastingActivityRepository(
        PersonalFastingActivitySnapshot(activeSession: durableActive),
      );
      final tracker = FastingTracker.fromSnapshot(
        snapshot: PersonalFastingActivitySnapshot(activeSession: localActive),
        nowUtc: () => DateTime.utc(2026, 7, 20),
      );
      final transitions = PersistFastingSessionTransitions(
        _FakeAppAccountSessionProvider(
          AppAccountSession(AppAccountId('app-account')),
        ),
        repository,
      );

      final outcome = await transitions.end(
        tracker: tracker,
        actualEndTime: DateTime.utc(2026, 7, 18, 20),
      );

      expect(outcome, isA<FastingSessionTransitionFailure>());
      expect(outcome.tracker, same(tracker));
      expect(outcome.tracker.activeSession?.id.value, 'local-active');
      expect(repository.snapshot.activeSession?.id.value, 'durable-active');
      expect(repository.upsertedSessions, isEmpty);
    },
  );

  test(
    'reconciles an exact end retry from the durable ended Fasting Session',
    () async {
      final endedSession = FastingSession(
        id: FastingSessionId('stable-session-id'),
        startTime: DateTime.utc(2026, 7, 18, 8),
        targetEndTime: DateTime.utc(2026, 7, 19),
        actualEndTime: DateTime.utc(2026, 7, 18, 20),
      );
      final repository = _InMemoryPersonalFastingActivityRepository(
        PersonalFastingActivitySnapshot(endedSessions: [endedSession]),
      );
      final staleActiveTracker = FastingTracker.fromSnapshot(
        snapshot: PersonalFastingActivitySnapshot(
          activeSession: FastingSession(
            id: endedSession.id,
            startTime: endedSession.startTime,
            targetEndTime: endedSession.targetEndTime,
          ),
        ),
        nowUtc: () => DateTime.utc(2026, 7, 20),
      );
      final transitions = PersistFastingSessionTransitions(
        _FakeAppAccountSessionProvider(
          AppAccountSession(AppAccountId('app-account')),
        ),
        repository,
      );

      final outcome = await transitions.end(
        tracker: staleActiveTracker,
        actualEndTime: endedSession.actualEndTime!,
      );

      expect(outcome, isA<PersistedFastingSessionTransition>());
      final persisted = outcome as PersistedFastingSessionTransition;
      expect(persisted.session.id, endedSession.id);
      expect(persisted.session.actualEndTime, endedSession.actualEndTime);
      expect(persisted.tracker.activeSession, isNull);
      expect(persisted.tracker.recentEndedSessions, hasLength(1));
      expect(repository.upsertedSessions, isEmpty);
    },
  );

  test(
    'rejects an end retry whose timestamp would correct durable ended activity',
    () async {
      final endedSession = FastingSession(
        id: FastingSessionId('stable-session-id'),
        startTime: DateTime.utc(2026, 7, 18, 8),
        targetEndTime: DateTime.utc(2026, 7, 19),
        actualEndTime: DateTime.utc(2026, 7, 18, 20),
      );
      final repository = _InMemoryPersonalFastingActivityRepository(
        PersonalFastingActivitySnapshot(endedSessions: [endedSession]),
      );
      final staleActiveTracker = FastingTracker.fromSnapshot(
        snapshot: PersonalFastingActivitySnapshot(
          activeSession: FastingSession(
            id: endedSession.id,
            startTime: endedSession.startTime,
            targetEndTime: endedSession.targetEndTime,
          ),
        ),
        nowUtc: () => DateTime.utc(2026, 7, 20),
      );
      final transitions = PersistFastingSessionTransitions(
        _FakeAppAccountSessionProvider(
          AppAccountSession(AppAccountId('app-account')),
        ),
        repository,
      );

      final outcome = await transitions.end(
        tracker: staleActiveTracker,
        actualEndTime: DateTime.utc(2026, 7, 18, 21),
      );

      expect(outcome, isA<FastingSessionTransitionFailure>());
      expect(outcome.tracker, same(staleActiveTracker));
      expect(
        repository.snapshot.endedSessions.single.actualEndTime,
        endedSession.actualEndTime,
      );
      expect(repository.upsertedSessions, isEmpty);
    },
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
  _InMemoryPersonalFastingActivityRepository([
    PersonalFastingActivitySnapshot? snapshot,
  ]) : _snapshot = snapshot ?? PersonalFastingActivitySnapshot();

  PersonalFastingActivitySnapshot _snapshot;
  final upsertedSessions = <FastingSession>[];
  final upsertedAccountIds = <AppAccountId>[];
  bool failEndedUpserts = false;

  PersonalFastingActivitySnapshot get snapshot => _snapshot;

  @override
  Future<PersonalFastingActivitySnapshot> loadSnapshot(
    AppAccountId accountId,
  ) async {
    return _snapshot;
  }

  @override
  Future<PersonalFastingActivitySnapshot> upsert(
    AppAccountId accountId,
    FastingSession session,
  ) async {
    if (failEndedUpserts && !session.isActive) {
      throw StateError('Firestore unavailable');
    }
    upsertedAccountIds.add(accountId);
    upsertedSessions.add(session);
    _snapshot = _snapshot.upsert(session);
    return _snapshot;
  }

  @override
  Future<PersonalFastingActivitySnapshot> endActiveSession(
    AppAccountId accountId,
    FastingSession endedSession,
  ) async {
    final activeSession = _snapshot.activeSession;
    if (activeSession?.id == endedSession.id &&
        activeSession?.startTime == endedSession.startTime &&
        activeSession?.targetEndTime == endedSession.targetEndTime) {
      return upsert(accountId, endedSession);
    }

    final persistedEndedSession = _snapshot.endedSessions
        .where((session) => session.id == endedSession.id)
        .firstOrNull;
    if (persistedEndedSession != null &&
        persistedEndedSession.startTime == endedSession.startTime &&
        persistedEndedSession.targetEndTime == endedSession.targetEndTime &&
        persistedEndedSession.actualEndTime == endedSession.actualEndTime) {
      return _snapshot;
    }

    throw StateError('Cannot end a Fasting Session outside durable activity');
  }

  @override
  Future<PersonalFastingActivitySnapshot> deleteEndedSession(
    AppAccountId accountId,
    FastingSessionId id,
  ) async {
    _snapshot = _snapshot.deleteEndedSession(id);
    return _snapshot;
  }
}

final class _FailingPersonalFastingActivityRepository
    implements PersonalFastingActivityRepository {
  const _FailingPersonalFastingActivityRepository();

  @override
  Future<PersonalFastingActivitySnapshot> loadSnapshot(
    AppAccountId accountId,
  ) => throw UnimplementedError();

  @override
  Future<PersonalFastingActivitySnapshot> upsert(
    AppAccountId accountId,
    FastingSession session,
  ) => Future.error(StateError('Firestore unavailable'));

  @override
  Future<PersonalFastingActivitySnapshot> endActiveSession(
    AppAccountId accountId,
    FastingSession endedSession,
  ) => Future.error(StateError('Firestore unavailable'));

  @override
  Future<PersonalFastingActivitySnapshot> deleteEndedSession(
    AppAccountId accountId,
    FastingSessionId id,
  ) => throw UnimplementedError();
}

final class _CommitThenThrowPersonalFastingActivityRepository
    implements PersonalFastingActivityRepository {
  PersonalFastingActivitySnapshot _snapshot = PersonalFastingActivitySnapshot();
  final upsertedSessions = <FastingSession>[];
  var _shouldThrowAfterCommit = true;

  @override
  Future<PersonalFastingActivitySnapshot> loadSnapshot(
    AppAccountId accountId,
  ) async {
    return _snapshot;
  }

  @override
  Future<PersonalFastingActivitySnapshot> upsert(
    AppAccountId accountId,
    FastingSession session,
  ) async {
    upsertedSessions.add(session);
    _snapshot = _snapshot.upsert(session);
    if (_shouldThrowAfterCommit) {
      _shouldThrowAfterCommit = false;
      throw StateError('Firestore acknowledgement was lost');
    }
    return _snapshot;
  }

  @override
  Future<PersonalFastingActivitySnapshot> endActiveSession(
    AppAccountId accountId,
    FastingSession endedSession,
  ) => throw UnimplementedError();

  @override
  Future<PersonalFastingActivitySnapshot> deleteEndedSession(
    AppAccountId accountId,
    FastingSessionId id,
  ) => throw UnimplementedError();
}

final class _AccountScopedCommitThenThrowRepository
    implements PersonalFastingActivityRepository {
  final _snapshots = <AppAccountId, PersonalFastingActivitySnapshot>{};
  final _upserts = <AppAccountId, List<FastingSession>>{};
  var _shouldThrowAfterCommit = true;

  PersonalFastingActivitySnapshot snapshotFor(AppAccountId accountId) {
    return _snapshots[accountId] ?? PersonalFastingActivitySnapshot();
  }

  List<FastingSession> upsertsFor(AppAccountId accountId) {
    return List.unmodifiable(_upserts[accountId] ?? const []);
  }

  @override
  Future<PersonalFastingActivitySnapshot> loadSnapshot(
    AppAccountId accountId,
  ) async {
    return snapshotFor(accountId);
  }

  @override
  Future<PersonalFastingActivitySnapshot> upsert(
    AppAccountId accountId,
    FastingSession session,
  ) async {
    _upserts.putIfAbsent(accountId, () => []).add(session);
    final snapshot = snapshotFor(accountId).upsert(session);
    _snapshots[accountId] = snapshot;
    if (_shouldThrowAfterCommit) {
      _shouldThrowAfterCommit = false;
      throw StateError('Firestore acknowledgement was lost');
    }
    return snapshot;
  }

  @override
  Future<PersonalFastingActivitySnapshot> endActiveSession(
    AppAccountId accountId,
    FastingSession endedSession,
  ) => throw UnimplementedError();

  @override
  Future<PersonalFastingActivitySnapshot> deleteEndedSession(
    AppAccountId accountId,
    FastingSessionId id,
  ) => throw UnimplementedError();
}
