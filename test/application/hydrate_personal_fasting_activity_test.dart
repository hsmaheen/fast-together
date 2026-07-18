import 'package:fasting_app/application/app_account_session.dart';
import 'package:fasting_app/application/fasting_tracker.dart';
import 'package:fasting_app/application/hydrate_personal_fasting_activity.dart';
import 'package:fasting_app/application/personal_fasting_activity_repository.dart';
import 'package:fasting_app/domain/fasting_plan.dart';
import 'package:fasting_app/domain/fasting_session.dart';
import 'package:fasting_app/domain/fasting_session_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hydrates empty Personal Fasting Activity as Not Fasting', () async {
    final hydrator = HydratePersonalFastingActivity(
      _FakeAppAccountSessionProvider(
        AppAccountSession(AppAccountId('app-account')),
      ),
      _FakePersonalFastingActivityRepository(PersonalFastingActivitySnapshot()),
    );

    final tracker = await hydrator.hydrate();

    expect(tracker.status, FastingStatus.notFasting);
    expect(tracker.activeSession, isNull);
    expect(tracker.recentEndedSessions, isEmpty);
  });

  test(
    'hydrates the signed-in App Account snapshot into a FastingTracker',
    () async {
      final activeSession = _activeSession('active-session');
      final repository = _FakePersonalFastingActivityRepository(
        PersonalFastingActivitySnapshot(
          activeSession: activeSession,
          endedSessions: [
            _endedSession('older-session', DateTime.utc(2026, 7, 15, 9)),
            _endedSession('newer-session', DateTime.utc(2026, 7, 16, 9)),
          ],
        ),
      );
      final accountId = AppAccountId('signed-in-app-account');
      final hydrator = HydratePersonalFastingActivity(
        _FakeAppAccountSessionProvider(AppAccountSession(accountId)),
        repository,
      );

      final tracker = await hydrator.hydrate();

      expect(repository.loadedAccountId, accountId);
      expect(tracker.status, FastingStatus.fasting);
      expect(tracker.activeSession?.id, activeSession.id);
      expect(tracker.recentEndedSessions.map((session) => session.id.value), [
        'newer-session',
        'older-session',
      ]);
    },
  );

  test('rejects hydration when no App Account is signed in', () async {
    final hydrator = HydratePersonalFastingActivity(
      const _FakeAppAccountSessionProvider(null),
      _FakePersonalFastingActivityRepository(PersonalFastingActivitySnapshot()),
    );

    await expectLater(hydrator.hydrate(), throwsStateError);
  });

  test(
    'rejects an invalid persisted snapshot without changing the caller tracker',
    () async {
      final existingTracker = FastingTracker(
        nowUtc: () => DateTime.utc(2026, 7, 18, 12),
        newSessionId: () => FastingSessionId('existing-active-session'),
      );
      existingTracker.start(
        startTime: DateTime.utc(2026, 7, 18, 8),
        plan: FastingPlan.sixteenHours,
      );
      final hydrator = HydratePersonalFastingActivity(
        _FakeAppAccountSessionProvider(
          AppAccountSession(AppAccountId('app-account')),
        ),
        const _FailingPersonalFastingActivityRepository(),
      );

      await expectLater(hydrator.hydrate(), throwsStateError);

      expect(existingTracker.status, FastingStatus.fasting);
      expect(
        existingTracker.activeSession?.id.value,
        'existing-active-session',
      );
      expect(existingTracker.recentEndedSessions, isEmpty);
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

final class _FakePersonalFastingActivityRepository
    implements PersonalFastingActivityRepository {
  _FakePersonalFastingActivityRepository(this._snapshot);

  final PersonalFastingActivitySnapshot _snapshot;
  AppAccountId? loadedAccountId;

  @override
  Future<PersonalFastingActivitySnapshot> loadSnapshot(
    AppAccountId accountId,
  ) async {
    loadedAccountId = accountId;
    return _snapshot;
  }

  @override
  Future<PersonalFastingActivitySnapshot> upsert(
    AppAccountId accountId,
    FastingSession session,
  ) => throw UnimplementedError();

  @override
  Future<PersonalFastingActivitySnapshot> endActiveSession(
    AppAccountId accountId,
    FastingSession endedSession,
  ) => throw UnimplementedError();

  @override
  Future<PersonalFastingActivitySnapshot> correctEndedSession(
    AppAccountId accountId,
    FastingSession previousSession,
    FastingSession correctedSession,
  ) => throw UnimplementedError();

  @override
  Future<PersonalFastingActivitySnapshot> deleteExactEndedSession(
    AppAccountId accountId,
    FastingSession expectedSession,
  ) => throw UnimplementedError();

  @override
  Future<PersonalFastingActivitySnapshot> deleteEndedSession(
    AppAccountId accountId,
    FastingSessionId id,
  ) => throw UnimplementedError();
}

final class _FailingPersonalFastingActivityRepository
    implements PersonalFastingActivityRepository {
  const _FailingPersonalFastingActivityRepository();

  @override
  Future<PersonalFastingActivitySnapshot> loadSnapshot(
    AppAccountId accountId,
  ) => Future.error(StateError('Invalid persisted Personal Fasting Activity'));

  @override
  Future<PersonalFastingActivitySnapshot> upsert(
    AppAccountId accountId,
    FastingSession session,
  ) => throw UnimplementedError();

  @override
  Future<PersonalFastingActivitySnapshot> endActiveSession(
    AppAccountId accountId,
    FastingSession endedSession,
  ) => throw UnimplementedError();

  @override
  Future<PersonalFastingActivitySnapshot> correctEndedSession(
    AppAccountId accountId,
    FastingSession previousSession,
    FastingSession correctedSession,
  ) => throw UnimplementedError();

  @override
  Future<PersonalFastingActivitySnapshot> deleteExactEndedSession(
    AppAccountId accountId,
    FastingSession expectedSession,
  ) => throw UnimplementedError();

  @override
  Future<PersonalFastingActivitySnapshot> deleteEndedSession(
    AppAccountId accountId,
    FastingSessionId id,
  ) => throw UnimplementedError();
}

FastingSession _activeSession(String id) {
  return FastingSession(
    id: FastingSessionId(id),
    startTime: DateTime.utc(2026, 7, 17, 8),
    targetEndTime: DateTime.utc(2026, 7, 18, 8),
  );
}

FastingSession _endedSession(String id, DateTime actualEndTime) {
  return FastingSession(
    id: FastingSessionId(id),
    startTime: actualEndTime.subtract(const Duration(hours: 16)),
    targetEndTime: actualEndTime,
    actualEndTime: actualEndTime,
  );
}
