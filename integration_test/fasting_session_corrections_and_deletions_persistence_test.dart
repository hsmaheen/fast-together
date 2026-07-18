import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fasting_app/application/app_account_session.dart';
import 'package:fasting_app/application/fasting_tracker.dart';
import 'package:fasting_app/application/hydrate_personal_fasting_activity.dart';
import 'package:fasting_app/application/persist_fasting_session_corrections_and_deletions.dart';
import 'package:fasting_app/application/persist_fasting_session_transitions.dart';
import 'package:fasting_app/application/personal_fasting_activity_repository.dart';
import 'package:fasting_app/data/firebase_emulator/firebase_emulator_app.dart';
import 'package:fasting_app/data/firebase_emulator/firebase_emulator_configuration.dart';
import 'package:fasting_app/data/firestore/firestore_personal_fasting_activity_repository.dart';
import 'package:fasting_app/domain/fasting_plan.dart';
import 'package:fasting_app/domain/fasting_session_id.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppAccountSessionProvider appAccountSessions;
  late AppAccountSession session;
  late PersonalFastingActivityRepository repository;
  late PersistFastingSessionTransitions transitions;
  late PersistFastingSessionCorrectionsAndDeletions mutations;

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
    mutations = PersistFastingSessionCorrectionsAndDeletions(
      appAccountSessions,
      repository,
    );
  });

  testWidgets(
    'restores corrected and deleted owner history across device reconstructions',
    (tester) async {
      await _clearPersonalFastingActivity(repository, session.accountId);
      addTearDown(
        () => _clearPersonalFastingActivity(repository, session.accountId),
      );

      final tracker = FastingTracker(
        nowUtc: () => DateTime.utc(2026, 7, 22),
        newSessionId: _sessionIds(["corrected-session", "retained-session"]),
      );
      final correctedSession =
          await transitions.start(
                tracker: tracker,
                startTime: DateTime.utc(2026, 7, 17, 8),
                plan: FastingPlan.sixteenHours,
              )
              as PersistedFastingSessionTransition;
      final firstEnded =
          await transitions.end(
                tracker: correctedSession.tracker,
                actualEndTime: DateTime.utc(2026, 7, 18, 1),
              )
              as PersistedFastingSessionTransition;
      final retainedSession =
          await transitions.start(
                tracker: firstEnded.tracker,
                startTime: DateTime.utc(2026, 7, 15, 8),
                plan: FastingPlan.sixteenHours,
              )
              as PersistedFastingSessionTransition;
      final secondEnded = _persistedTransition(
        await transitions.end(
          tracker: retainedSession.tracker,
          actualEndTime: DateTime.utc(2026, 7, 16),
        ),
      );

      final firstReconstruction = await HydratePersonalFastingActivity(
        appAccountSessions,
        repository,
      ).hydrate();
      expect(
        firstReconstruction.recentEndedSessions.map((item) => item.id.value),
        ['corrected-session', 'retained-session'],
      );
      expect(secondEnded.session.id.value, 'retained-session');

      final corrected =
          await mutations.correctActualEndTime(
                tracker: firstReconstruction,
                id: FastingSessionId('corrected-session'),
                actualEndTime: DateTime.utc(2026, 7, 18, 3),
              )
              as PersistedFastingSessionMutation;
      final correctedDocument = await _ownerSessionDocument(
        session.accountId,
        FastingSessionId('corrected-session'),
      ).get(const GetOptions(source: Source.server));

      expect(corrected.session.id.value, 'corrected-session');
      expect(corrected.session.startTime, DateTime.utc(2026, 7, 17, 8));
      expect(corrected.session.targetEndTime, DateTime.utc(2026, 7, 18));
      expect(corrected.session.actualEndTime, DateTime.utc(2026, 7, 18, 3));
      expect(correctedDocument.id, 'corrected-session');
      expect(
        (correctedDocument.get('actualEndTime') as Timestamp).toDate().toUtc(),
        DateTime.utc(2026, 7, 18, 3),
      );
      expect(
        corrected.tracker.dailyFastingTotals(localTimeFor: (time) => time),
        [
          DailyFastingTotal(
            date: DateTime(2026, 7, 18),
            duration: const Duration(hours: 19),
          ),
          DailyFastingTotal(
            date: DateTime(2026, 7, 16),
            duration: const Duration(hours: 16),
          ),
        ],
      );

      final deleted =
          await mutations.deleteEndedSession(
                tracker: corrected.tracker,
                id: FastingSessionId('corrected-session'),
              )
              as PersistedFastingSessionMutation;
      final deletedDocument = await _ownerSessionDocument(
        session.accountId,
        FastingSessionId('corrected-session'),
      ).get(const GetOptions(source: Source.server));
      final secondReconstruction = await HydratePersonalFastingActivity(
        appAccountSessions,
        repository,
      ).hydrate();

      expect(deletedDocument.exists, isFalse);
      expect(deleted.tracker.recentEndedSessions.map((item) => item.id.value), [
        'retained-session',
      ]);
      expect(
        secondReconstruction.recentEndedSessions.map((item) => item.id.value),
        ['retained-session'],
      );
      expect(
        secondReconstruction.dailyFastingTotals(localTimeFor: (time) => time),
        [
          DailyFastingTotal(
            date: DateTime(2026, 7, 16),
            duration: const Duration(hours: 16),
          ),
        ],
      );

      await _expectOtherAccountCannotReadOrMutate(
        ownerAccountId: session.accountId,
        sessionId: FastingSessionId('retained-session'),
      );
    },
  );
}

FastingSessionId Function() _sessionIds(List<String> ids) {
  final iterator = ids.iterator;
  return () {
    if (!iterator.moveNext()) {
      throw StateError('Test requested an unexpected Fasting Session ID');
    }
    return FastingSessionId(iterator.current);
  };
}

PersistedFastingSessionTransition _persistedTransition(
  FastingSessionTransition outcome,
) {
  if (outcome case final FastingSessionTransitionFailure failure) {
    fail('Expected a persisted lifecycle transition: ${failure.error}');
  }
  return outcome as PersistedFastingSessionTransition;
}

DocumentReference<Map<String, dynamic>> _ownerSessionDocument(
  AppAccountId accountId,
  FastingSessionId sessionId,
) {
  return FirebaseFirestore.instance
      .collection('appAccounts')
      .doc(accountId.value)
      .collection('fastingSessions')
      .doc(sessionId.value);
}

Future<void> _expectOtherAccountCannotReadOrMutate({
  required AppAccountId ownerAccountId,
  required FastingSessionId sessionId,
}) async {
  final appName = 'lif79-other-account';
  final otherApp = await Firebase.initializeApp(
    name: appName,
    options: Firebase.app().options,
  );
  final hosts = _emulatorHostsForCurrentPlatform();
  final auth = FirebaseAuth.instanceFor(app: otherApp);
  final firestore = FirebaseFirestore.instanceFor(app: otherApp);
  await auth.useAuthEmulator(
    hosts.authHost,
    hosts.authPort,
    automaticHostMapping: false,
  );
  firestore.useFirestoreEmulator(
    hosts.firestoreHost,
    hosts.firestorePort,
    sslEnabled: false,
  );

  try {
    await _signInOrCreateOtherLocalAccount(auth);
    final ownerDocument = firestore
        .collection('appAccounts')
        .doc(ownerAccountId.value)
        .collection('fastingSessions')
        .doc(sessionId.value);

    await expectLater(
      ownerDocument.get(const GetOptions(source: Source.server)),
      throwsA(_permissionDenied),
    );
    await expectLater(
      ownerDocument.set({
        'startTime': Timestamp.fromDate(DateTime.utc(2026, 7, 15, 8)),
        'targetEndTime': Timestamp.fromDate(DateTime.utc(2026, 7, 16)),
        'actualEndTime': Timestamp.fromDate(DateTime.utc(2026, 7, 16)),
      }),
      throwsA(_permissionDenied),
    );
  } finally {
    await auth.signOut();
    await otherApp.delete();
  }
}

Matcher get _permissionDenied => isA<FirebaseException>().having(
  (error) => error.code,
  'code',
  'permission-denied',
);

Future<void> _signInOrCreateOtherLocalAccount(FirebaseAuth auth) async {
  const email = 'lif79-other-account@demo-fasting-app.invalid';
  const password = 'local-emulator-only-password';
  try {
    await auth.signInWithEmailAndPassword(email: email, password: password);
  } on FirebaseAuthException catch (error) {
    if (!_isMissingLocalEmulatorAccount(error)) {
      rethrow;
    }
    try {
      await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (createError) {
      if (createError.code != 'email-already-in-use') {
        rethrow;
      }
      await auth.signInWithEmailAndPassword(email: email, password: password);
    }
  }
}

bool _isMissingLocalEmulatorAccount(FirebaseAuthException error) {
  return error.code == 'user-not-found' ||
      error.code == 'invalid-credential' ||
      error.code == 'INVALID_LOGIN_CREDENTIALS' ||
      (error.code == 'unknown' &&
          error.message?.contains('INVALID_LOGIN_CREDENTIALS') == true);
}

FirebaseEmulatorHosts _emulatorHostsForCurrentPlatform() {
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => FirebaseEmulatorHosts.forTarget(
      FirebaseEmulatorTarget.iosSimulator,
    ),
    TargetPlatform.android => FirebaseEmulatorHosts.forTarget(
      FirebaseEmulatorTarget.androidEmulator,
    ),
    _ => throw UnsupportedError(
      'Firebase Emulator tests require an iOS Simulator or Android Emulator',
    ),
  };
}

Future<void> _clearPersonalFastingActivity(
  PersonalFastingActivityRepository repository,
  AppAccountId accountId,
) async {
  var snapshot = await repository.loadSnapshot(accountId);
  final activeSession = snapshot.activeSession;
  if (activeSession != null) {
    snapshot = await repository.endActiveSession(
      accountId,
      activeSession.end(actualEndTime: activeSession.targetEndTime),
    );
  }

  for (final session in snapshot.endedSessions) {
    snapshot = await repository.deleteExactEndedSession(accountId, session);
  }
}
