import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fasting_app/application/app_account_session.dart';
import 'package:fasting_app/application/fasting_tracker.dart';
import 'package:fasting_app/application/hydrate_personal_fasting_activity.dart';
import 'package:fasting_app/application/persist_fasting_session_transitions.dart';
import 'package:fasting_app/application/personal_fasting_activity_repository.dart';
import 'package:fasting_app/data/firebase_emulator/firebase_emulator_app.dart';
import 'package:fasting_app/data/firestore/firestore_personal_fasting_activity_repository.dart';
import 'package:fasting_app/domain/fasting_plan.dart';
import 'package:fasting_app/domain/fasting_session_id.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppAccountSessionProvider appAccountSessions;
  late AppAccountSession session;
  late PersonalFastingActivityRepository repository;
  late PersistFastingSessionTransitions transitions;

  setUpAll(() async {
    appAccountSessions = await initializeFirebaseEmulatorApp();
    session = await appAccountSessions.signInOrCreateForLocalEmulator();
    repository = FirestorePersonalFastingActivityRepository(
      firestore: FirebaseFirestore.instance,
      appAccountSession: session,
    );
    transitions = PersistFastingSessionTransitions(
      appAccountSessions,
      repository,
    );
  });

  testWidgets(
    'persists start and end transitions then restores ended Personal Fasting Activity',
    (tester) async {
      await _clearPersonalFastingActivity(repository, session.accountId);
      addTearDown(
        () => _clearPersonalFastingActivity(repository, session.accountId),
      );

      final started =
          await transitions.start(
                tracker: FastingTracker(
                  nowUtc: () => DateTime.utc(2026, 7, 20),
                  newSessionId: () => FastingSessionId('lifecycle-session'),
                ),
                startTime: DateTime.utc(2026, 7, 18, 8),
                plan: FastingPlan.sixteenHours,
              )
              as PersistedFastingSessionTransition;
      final ended =
          await transitions.end(
                tracker: started.tracker,
                actualEndTime: DateTime.utc(2026, 7, 19, 8),
              )
              as PersistedFastingSessionTransition;

      final reconstructed = await HydratePersonalFastingActivity(
        appAccountSessions,
        repository,
      ).hydrate();

      expect(ended.session.id.value, 'lifecycle-session');
      expect(ended.session.actualEndTime, DateTime.utc(2026, 7, 19, 8));
      expect(reconstructed.status, FastingStatus.notFasting);
      expect(reconstructed.activeSession, isNull);
      expect(
        reconstructed.recentEndedSessions.map((session) => session.id.value),
        ['lifecycle-session'],
      );
      expect(
        reconstructed.recentEndedSessions.single.actualEndTime,
        DateTime.utc(2026, 7, 19, 8),
      );
    },
  );
}

Future<void> _clearPersonalFastingActivity(
  PersonalFastingActivityRepository repository,
  AppAccountId accountId,
) async {
  var snapshot = await repository.loadSnapshot(accountId);
  final activeSession = snapshot.activeSession;
  if (activeSession != null) {
    snapshot = await repository.upsert(
      accountId,
      activeSession.end(actualEndTime: activeSession.targetEndTime),
    );
  }

  for (final session in snapshot.endedSessions) {
    await repository.deleteEndedSession(accountId, session.id);
  }
}
