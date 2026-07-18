import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fasting_app/application/app_account_session.dart';
import 'package:fasting_app/application/personal_fasting_activity_repository.dart';
import 'package:fasting_app/data/firebase_emulator/firebase_emulator_app.dart';
import 'package:fasting_app/data/firestore/firestore_personal_fasting_activity_repository.dart';
import 'package:fasting_app/domain/fasting_session.dart';
import 'package:fasting_app/domain/fasting_session_id.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppAccountSession session;
  late FirestorePersonalFastingActivityRepository repository;

  setUpAll(() async {
    final sessions = await initializeFirebaseEmulatorApp();
    session = await sessions.signInOrCreateForLocalEmulator();
    repository = FirestorePersonalFastingActivityRepository(
      firestore: FirebaseFirestore.instance,
      appAccountSession: session,
    );
  });

  testWidgets('an owner saves, ends, and loads a Fasting Session', (
    tester,
  ) async {
    await _clearPersonalFastingActivity(repository, session.accountId);
    final fastingSession = FastingSession(
      id: FastingSessionId('owner-active-session'),
      startTime: DateTime.utc(2026, 7, 18, 8),
      targetEndTime: DateTime.utc(2026, 7, 19, 8),
    );

    final saved = await repository.upsert(session.accountId, fastingSession);
    final loaded = await repository.loadSnapshot(session.accountId);
    final storedDocument = await FirebaseFirestore.instance
        .collection('appAccounts')
        .doc(session.accountId.value)
        .collection('fastingSessions')
        .doc(fastingSession.id.value)
        .get(const GetOptions(source: Source.server));

    expect(saved.activeSession?.id, fastingSession.id);
    expect(saved.activeSession?.startTime, fastingSession.startTime);
    expect(saved.activeSession?.targetEndTime, fastingSession.targetEndTime);
    expect(loaded.activeSession?.id, fastingSession.id);
    expect(loaded.activeSession?.startTime, fastingSession.startTime);
    expect(loaded.activeSession?.targetEndTime, fastingSession.targetEndTime);
    expect(loaded.endedSessions, isEmpty);
    expect(storedDocument.id, fastingSession.id.value);
    expect(storedDocument.get('startTime'), isA<Timestamp>());
    expect(storedDocument.get('targetEndTime'), isA<Timestamp>());
    expect(storedDocument.data()?.keys, {'startTime', 'targetEndTime'});

    final endedSession = fastingSession.end(
      actualEndTime: DateTime.utc(2026, 7, 19, 8),
    );
    final ended = await repository.upsert(session.accountId, endedSession);
    final endedDocument = await FirebaseFirestore.instance
        .collection('appAccounts')
        .doc(session.accountId.value)
        .collection('fastingSessions')
        .doc(fastingSession.id.value)
        .get(const GetOptions(source: Source.server));

    expect(ended.activeSession, isNull);
    expect(ended.endedSessions.single.id, fastingSession.id);
    expect(
      ended.endedSessions.single.actualEndTime,
      endedSession.actualEndTime,
    );
    expect(ended.endedSessions.single.result, FastingResult.completed);
    expect(endedDocument.get('actualEndTime'), isA<Timestamp>());
    expect(endedDocument.data()?.keys, {
      'startTime',
      'targetEndTime',
      'actualEndTime',
    });

    final deleted = await repository.deleteEndedSession(
      session.accountId,
      fastingSession.id,
    );
    final deletedDocument = await FirebaseFirestore.instance
        .collection('appAccounts')
        .doc(session.accountId.value)
        .collection('fastingSessions')
        .doc(fastingSession.id.value)
        .get(const GetOptions(source: Source.server));

    expect(deleted.activeSession, isNull);
    expect(deleted.endedSessions, isEmpty);
    expect(deletedDocument.exists, isFalse);
  });

  testWidgets(
    'idempotently upserts by ID and rejects a second active Fasting Session',
    (tester) async {
      await _clearPersonalFastingActivity(repository, session.accountId);
      final activeSession = FastingSession(
        id: FastingSessionId('idempotent-session'),
        startTime: DateTime.utc(2026, 7, 17, 8),
        targetEndTime: DateTime.utc(2026, 7, 18, 8),
      );

      final firstUpsert = await repository.upsert(
        session.accountId,
        activeSession,
      );
      final repeatedUpsert = await repository.upsert(
        session.accountId,
        activeSession,
      );
      final secondActiveSession = FastingSession(
        id: FastingSessionId('second-active-session'),
        startTime: DateTime.utc(2026, 7, 18, 9),
        targetEndTime: DateTime.utc(2026, 7, 19, 9),
      );

      await expectLater(
        repository.upsert(session.accountId, secondActiveSession),
        throwsStateError,
      );
      final afterRejectedActiveUpsert = await repository.loadSnapshot(
        session.accountId,
      );

      expect(firstUpsert.activeSession?.id, activeSession.id);
      expect(repeatedUpsert.activeSession?.id, activeSession.id);
      expect(afterRejectedActiveUpsert.activeSession?.id, activeSession.id);
      expect(afterRejectedActiveUpsert.endedSessions, isEmpty);

      final endedSession = activeSession.end(
        actualEndTime: DateTime.utc(2026, 7, 18, 2),
      );
      await repository.upsert(session.accountId, endedSession);
      final correctedSession = endedSession.correctActualEndTime(
        actualEndTime: DateTime.utc(2026, 7, 18, 3),
      );
      final correctedUpsert = await repository.upsert(
        session.accountId,
        correctedSession,
      );
      final repeatedCorrectedUpsert = await repository.upsert(
        session.accountId,
        correctedSession,
      );

      expect(correctedUpsert.activeSession, isNull);
      expect(correctedUpsert.endedSessions, hasLength(1));
      expect(
        correctedUpsert.endedSessions.single.actualEndTime,
        correctedSession.actualEndTime,
      );
      expect(
        correctedUpsert.endedSessions.single.result,
        FastingResult.endedEarly,
      );
      expect(repeatedCorrectedUpsert.endedSessions, hasLength(1));
      expect(
        repeatedCorrectedUpsert.endedSessions.single.actualEndTime,
        correctedSession.actualEndTime,
      );

      await _clearPersonalFastingActivity(repository, session.accountId);
    },
  );

  testWidgets(
    'rejects another account path and invalid ended-session deletions',
    (tester) async {
      await _clearPersonalFastingActivity(repository, session.accountId);
      final activeSession = FastingSession(
        id: FastingSessionId('protected-active-session'),
        startTime: DateTime.utc(2026, 7, 16, 8),
        targetEndTime: DateTime.utc(2026, 7, 17, 8),
      );

      await expectLater(
        repository.loadSnapshot(AppAccountId('another-app-account')),
        throwsStateError,
      );
      await repository.upsert(session.accountId, activeSession);
      await expectLater(
        repository.deleteEndedSession(session.accountId, activeSession.id),
        throwsStateError,
      );
      final afterRejectedActiveDeletion = await repository.loadSnapshot(
        session.accountId,
      );

      expect(afterRejectedActiveDeletion.activeSession?.id, activeSession.id);

      final endedSession = activeSession.end(
        actualEndTime: DateTime.utc(2026, 7, 17, 7),
      );
      await repository.upsert(session.accountId, endedSession);
      await expectLater(
        repository.deleteEndedSession(
          session.accountId,
          FastingSessionId('missing-ended-session'),
        ),
        throwsStateError,
      );
      final afterRejectedMissingDeletion = await repository.loadSnapshot(
        session.accountId,
      );

      expect(afterRejectedMissingDeletion.activeSession, isNull);
      expect(
        afterRejectedMissingDeletion.endedSessions.single.id,
        activeSession.id,
      );

      await _clearPersonalFastingActivity(repository, session.accountId);
    },
  );

  testWidgets('hydrates ended Fasting Sessions in deterministic order', (
    tester,
  ) async {
    await _clearPersonalFastingActivity(repository, session.accountId);
    final olderSession = _endedSession(
      id: 'older-session',
      actualEndTime: DateTime.utc(2026, 7, 16, 1),
    );
    final tieLastSession = _endedSession(
      id: 'tie-z-session',
      actualEndTime: DateTime.utc(2026, 7, 17, 1),
    );
    final newerSession = _endedSession(
      id: 'newer-session',
      actualEndTime: DateTime.utc(2026, 7, 18, 1),
    );
    final tieFirstSession = _endedSession(
      id: 'tie-a-session',
      actualEndTime: DateTime.utc(2026, 7, 17, 1),
    );

    await repository.upsert(session.accountId, olderSession);
    await repository.upsert(session.accountId, tieLastSession);
    await repository.upsert(session.accountId, newerSession);
    await repository.upsert(session.accountId, tieFirstSession);
    final hydrated = await repository.loadSnapshot(session.accountId);

    expect(hydrated.activeSession, isNull);
    expect(hydrated.endedSessions.map((session) => session.id.value), [
      'newer-session',
      'tie-a-session',
      'tie-z-session',
      'older-session',
    ]);

    await _clearPersonalFastingActivity(repository, session.accountId);
  });

  testWidgets(
    'rejects a missing active-session sentinel before loading or upserting',
    (tester) async {
      await _clearFirestoreForTest();
      final orphanedActiveSession = FastingSession(
        id: FastingSessionId('legacy-active-without-state'),
        startTime: DateTime.utc(2026, 7, 18, 8),
        targetEndTime: DateTime.utc(2026, 7, 19, 8),
      );
      final attemptedActiveSession = FastingSession(
        id: FastingSessionId('attempted-active-after-legacy-state'),
        startTime: DateTime.utc(2026, 7, 18, 9),
        targetEndTime: DateTime.utc(2026, 7, 19, 9),
      );
      await _seedFastingSession(session.accountId, orphanedActiveSession);

      try {
        await expectLater(
          repository.loadSnapshot(session.accountId),
          throwsStateError,
        );
        await expectLater(
          repository.upsert(session.accountId, attemptedActiveSession),
          throwsStateError,
        );

        await _seedActiveSessionState(
          session.accountId,
          orphanedActiveSession.id.value,
        );
        final repairedSnapshot = await repository.loadSnapshot(
          session.accountId,
        );

        expect(repairedSnapshot.activeSession?.id, orphanedActiveSession.id);
        expect(repairedSnapshot.endedSessions, isEmpty);
      } finally {
        await _clearFirestoreForTest();
      }
    },
  );

  testWidgets('rejects a stale sentinel without an active Fasting Session', (
    tester,
  ) async {
    await _clearFirestoreForTest();
    await _seedActiveSessionState(
      session.accountId,
      'missing-legacy-active-session',
    );

    try {
      await expectLater(
        repository.loadSnapshot(session.accountId),
        throwsStateError,
      );
    } finally {
      await _clearFirestoreForTest();
    }
  });

  testWidgets('rejects deletion before mutating stale Personal Fasting Activity', (
    tester,
  ) async {
    await _clearFirestoreForTest();
    final endedSession = _endedSession(
      id: 'ended-session-with-stale-state',
      actualEndTime: DateTime.utc(2026, 7, 18, 1),
    );
    await _seedFastingSession(session.accountId, endedSession);
    await _seedActiveSessionState(
      session.accountId,
      'missing-legacy-active-session',
    );

    try {
      await expectLater(
        repository.deleteEndedSession(session.accountId, endedSession.id),
        throwsStateError,
      );

      await _deleteDocument(
        'appAccounts/${session.accountId.value}/personalFastingActivity/current',
      );
      final repairedSnapshot = await repository.loadSnapshot(
        session.accountId,
      );

      expect(repairedSnapshot.endedSessions.single.id, endedSession.id);
    } finally {
      await _clearFirestoreForTest();
    }
  });

  testWidgets('rejects a sentinel that names a different active Fasting Session', (
    tester,
  ) async {
    await _clearFirestoreForTest();
    final activeSession = FastingSession(
      id: FastingSessionId('hydrated-active-session'),
      startTime: DateTime.utc(2026, 7, 18, 8),
      targetEndTime: DateTime.utc(2026, 7, 19, 8),
    );
    await _seedFastingSession(session.accountId, activeSession);
    await _seedActiveSessionState(
      session.accountId,
      'different-active-session',
    );

    try {
      await expectLater(
        repository.loadSnapshot(session.accountId),
        throwsStateError,
      );
    } finally {
      await _clearFirestoreForTest();
    }
  });

  testWidgets('rejects a malformed sentinel for the hydrated active session', (
    tester,
  ) async {
    await _clearFirestoreForTest();
    final activeSession = FastingSession(
      id: FastingSessionId('active-session-with-malformed-state'),
      startTime: DateTime.utc(2026, 7, 18, 8),
      targetEndTime: DateTime.utc(2026, 7, 19, 8),
    );
    await _seedFastingSession(session.accountId, activeSession);
    await _seedDocument(
      path:
          'appAccounts/${session.accountId.value}/personalFastingActivity/current',
      fields: {
        'activeSessionId': {'stringValue': activeSession.id.value},
        'unexpectedLegacyField': {'stringValue': 'not-valid-state'},
      },
    );

    try {
      await expectLater(
        repository.loadSnapshot(session.accountId),
        throwsStateError,
      );
    } finally {
      await _clearFirestoreForTest();
    }
  });

  testWidgets(
    'loads an ended Fasting Session when its active-to-ended transaction follows the session read',
    (tester) async {
      await _clearPersonalFastingActivity(repository, session.accountId);
      final activeSession = FastingSession(
        id: FastingSessionId('concurrently-ended-session'),
        startTime: DateTime.utc(2026, 7, 18, 8),
        targetEndTime: DateTime.utc(2026, 7, 19, 8),
      );
      final endedSession = activeSession.end(
        actualEndTime: DateTime.utc(2026, 7, 18, 20),
      );
      await repository.upsert(session.accountId, activeSession);

      var endedBetweenServerReads = false;
      final interleavedRepository = FirestorePersonalFastingActivityRepository(
        firestore: FirebaseFirestore.instance,
        appAccountSession: session,
        afterFastingSessionsRead: () async {
          if (endedBetweenServerReads) {
            return;
          }
          endedBetweenServerReads = true;
          await _endActiveSessionInTransaction(session.accountId, endedSession);
        },
      );

      try {
        final snapshot = await interleavedRepository.loadSnapshot(
          session.accountId,
        );

        expect(endedBetweenServerReads, isTrue);
        expect(snapshot.activeSession, isNull);
        expect(snapshot.endedSessions.single.id, endedSession.id);
        expect(
          snapshot.endedSessions.single.actualEndTime,
          endedSession.actualEndTime,
        );
      } finally {
        await _clearPersonalFastingActivity(repository, session.accountId);
      }
    },
  );

  testWidgets(
    'upserts after an active-to-ended transaction follows its preflight session read',
    (tester) async {
      await _clearPersonalFastingActivity(repository, session.accountId);
      final activeSession = FastingSession(
        id: FastingSessionId('preflight-concurrently-ended-session'),
        startTime: DateTime.utc(2026, 7, 18, 8),
        targetEndTime: DateTime.utc(2026, 7, 19, 8),
      );
      final endedSession = activeSession.end(
        actualEndTime: DateTime.utc(2026, 7, 18, 20),
      );
      final nextActiveSession = FastingSession(
        id: FastingSessionId('active-session-after-preflight-transition'),
        startTime: DateTime.utc(2026, 7, 19, 8),
        targetEndTime: DateTime.utc(2026, 7, 20, 8),
      );
      await repository.upsert(session.accountId, activeSession);

      var endedBetweenServerReads = false;
      final interleavedRepository = FirestorePersonalFastingActivityRepository(
        firestore: FirebaseFirestore.instance,
        appAccountSession: session,
        afterFastingSessionsRead: () async {
          if (endedBetweenServerReads) {
            return;
          }
          endedBetweenServerReads = true;
          await _endActiveSessionInTransaction(session.accountId, endedSession);
        },
      );

      try {
        final snapshot = await interleavedRepository.upsert(
          session.accountId,
          nextActiveSession,
        );

        expect(endedBetweenServerReads, isTrue);
        expect(snapshot.activeSession?.id, nextActiveSession.id);
        expect(snapshot.endedSessions.single.id, endedSession.id);
      } finally {
        await _clearPersonalFastingActivity(repository, session.accountId);
      }
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

  for (final endedSession in snapshot.endedSessions) {
    snapshot = await repository.deleteEndedSession(accountId, endedSession.id);
  }

  expect(snapshot.activeSession, isNull);
  expect(snapshot.endedSessions, isEmpty);
}

Future<void> _clearFirestoreForTest() async {
  final response = await _emulatorRequest(
    method: 'DELETE',
    path: '/emulator/v1/projects/demo-fasting-app/databases/(default)/documents',
  );
  if (response.statusCode != HttpStatus.ok) {
    throw StateError('Could not clear the Firestore Emulator for this test');
  }
}

Future<void> _seedFastingSession(
  AppAccountId accountId,
  FastingSession fastingSession,
) async {
  final fields = <String, Object>{
    'startTime': {'timestampValue': fastingSession.startTime.toIso8601String()},
    'targetEndTime': {
      'timestampValue': fastingSession.targetEndTime.toIso8601String(),
    },
  };
  final actualEndTime = fastingSession.actualEndTime;
  if (actualEndTime != null) {
    fields['actualEndTime'] = {
      'timestampValue': actualEndTime.toIso8601String(),
    };
  }

  await _seedDocument(
    path:
        'appAccounts/${accountId.value}/fastingSessions/${fastingSession.id.value}',
    fields: fields,
  );
}

Future<void> _seedActiveSessionState(
  AppAccountId accountId,
  String activeSessionId,
) {
  return _seedDocument(
    path: 'appAccounts/${accountId.value}/personalFastingActivity/current',
    fields: {
      'activeSessionId': {'stringValue': activeSessionId},
    },
  );
}

Future<void> _endActiveSessionInTransaction(
  AppAccountId accountId,
  FastingSession endedSession,
) async {
  final firestore = FirebaseFirestore.instance;
  final sessionDocument = firestore
      .collection('appAccounts')
      .doc(accountId.value)
      .collection('fastingSessions')
      .doc(endedSession.id.value);
  final stateDocument = firestore
      .collection('appAccounts')
      .doc(accountId.value)
      .collection('personalFastingActivity')
      .doc('current');

  await firestore.runTransaction<void>((transaction) async {
    final persistedSession = await transaction.get(sessionDocument);
    final persistedState = await transaction.get(stateDocument);
    if (!persistedSession.exists ||
        !persistedState.exists ||
        persistedState.data()?['activeSessionId'] != endedSession.id.value) {
      throw StateError('Expected the active Fasting Session before ending it');
    }

    transaction.set(sessionDocument, {
      'startTime': Timestamp.fromDate(endedSession.startTime),
      'targetEndTime': Timestamp.fromDate(endedSession.targetEndTime),
      'actualEndTime': Timestamp.fromDate(endedSession.actualEndTime!),
    });
    transaction.delete(stateDocument);
  });
}

Future<void> _seedDocument({
  required String path,
  required Map<String, Object> fields,
}) async {
  final response = await _emulatorRequest(
    method: 'PATCH',
    path: '/v1/projects/demo-fasting-app/databases/(default)/documents/$path',
    body: {'fields': fields},
  );
  if (response.statusCode != HttpStatus.ok) {
    throw StateError('Could not seed the Firestore Emulator for this test');
  }
}

Future<void> _deleteDocument(String path) async {
  final response = await _emulatorRequest(
    method: 'DELETE',
    path: '/v1/projects/demo-fasting-app/databases/(default)/documents/$path',
  );
  if (response.statusCode != HttpStatus.ok) {
    throw StateError('Could not repair the Firestore Emulator for this test');
  }
}

Future<HttpClientResponse> _emulatorRequest({
  required String method,
  required String path,
  Map<String, Object>? body,
}) async {
  final client = HttpClient();
  final request = await client.openUrl(
    method,
    Uri(
      scheme: 'http',
      host: _firestoreEmulatorHost,
      port: 8080,
      path: path,
    ),
  );
  request.headers.set(HttpHeaders.authorizationHeader, 'Bearer owner');
  if (body != null) {
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(body));
  }

  return request.close();
}

String get _firestoreEmulatorHost => switch (defaultTargetPlatform) {
  TargetPlatform.android => '10.0.2.2',
  TargetPlatform.iOS => '127.0.0.1',
  _ => throw UnsupportedError('Firebase Emulator tests require a simulator'),
};
