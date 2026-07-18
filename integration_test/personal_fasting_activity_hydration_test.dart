import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fasting_app/application/fasting_tracker.dart';
import 'package:fasting_app/application/hydrate_personal_fasting_activity.dart';
import 'package:fasting_app/application/personal_fasting_activity_repository.dart';
import 'package:fasting_app/data/firebase_emulator/firebase_emulator_app.dart';
import 'package:fasting_app/data/firestore/firestore_personal_fasting_activity_repository.dart';
import 'package:fasting_app/domain/fasting_session.dart';
import 'package:fasting_app/domain/fasting_session_id.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FirestorePersonalFastingActivityRepository repository;
  late HydratePersonalFastingActivity hydrator;
  late AppAccountId accountId;

  setUpAll(() async {
    final appAccountSessions = await initializeFirebaseEmulatorApp();
    final session = await appAccountSessions.signInOrCreateForLocalEmulator();
    accountId = session.accountId;
    repository = FirestorePersonalFastingActivityRepository(
      firestore: FirebaseFirestore.instance,
      appAccountSession: session,
    );
    hydrator = HydratePersonalFastingActivity(appAccountSessions, repository);
  });

  testWidgets(
    'hydrates an authenticated persisted snapshot into a FastingTracker',
    (tester) async {
      await _clearPersonalFastingActivity(repository, accountId);
      addTearDown(() => _clearPersonalFastingActivity(repository, accountId));
      final endedSession = FastingSession(
        id: FastingSessionId('hydrated-ended-session'),
        startTime: DateTime.utc(2026, 7, 16, 8),
        targetEndTime: DateTime.utc(2026, 7, 17, 8),
        actualEndTime: DateTime.utc(2026, 7, 17, 8),
      );
      final activeSession = FastingSession(
        id: FastingSessionId('hydrated-active-session'),
        startTime: DateTime.utc(2026, 7, 18, 8),
        targetEndTime: DateTime.utc(2026, 7, 19, 8),
      );
      await repository.upsert(accountId, endedSession);
      await repository.upsert(accountId, activeSession);

      final tracker = await hydrator.hydrate();

      expect(tracker.status, FastingStatus.fasting);
      expect(tracker.activeSession?.id, activeSession.id);
      expect(tracker.activeSession?.startTime, activeSession.startTime);
      expect(tracker.activeSession?.targetEndTime, activeSession.targetEndTime);
      expect(tracker.activeSession?.startTime.isUtc, isTrue);
      expect(tracker.activeSession?.targetEndTime.isUtc, isTrue);
      expect(tracker.recentEndedSessions.map((session) => session.id), [
        endedSession.id,
      ]);
      expect(
        tracker.recentEndedSessions.single.actualEndTime,
        endedSession.actualEndTime,
      );
      expect(tracker.recentEndedSessions.single.actualEndTime?.isUtc, isTrue);
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
