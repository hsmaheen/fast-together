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

  test('repeats the same end as an idempotent durable upsert', () async {
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
    expect(repository.upsertedSessions, hasLength(3));
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
  Future<PersonalFastingActivitySnapshot> deleteEndedSession(
    AppAccountId accountId,
    FastingSessionId id,
  ) => throw UnimplementedError();
}
