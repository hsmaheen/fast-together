// Firebase construction parameter names are public; the SDK values stay private.
// ignore_for_file: prefer_initializing_formals

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fasting_app/application/app_account_session.dart';
import 'package:fasting_app/application/personal_fasting_activity_repository.dart';
import 'package:fasting_app/domain/fasting_session.dart';
import 'package:fasting_app/domain/fasting_session_id.dart';

final class FirestorePersonalFastingActivityRepository
    implements PersonalFastingActivityRepository {
  FirestorePersonalFastingActivityRepository({
    required FirebaseFirestore firestore,
    required AppAccountSession appAccountSession,
  }) : _firestore = firestore,
       _appAccountSession = appAccountSession;

  final FirebaseFirestore _firestore;
  final AppAccountSession _appAccountSession;

  @override
  Future<PersonalFastingActivitySnapshot> loadSnapshot(
    AppAccountId accountId,
  ) async {
    final ownerAccountId = _ownerAccountIdFor(accountId);
    final documents = await _fastingSessions(
      ownerAccountId,
    ).get(const GetOptions(source: Source.server));
    final sessions = documents.docs.map(_sessionFromDocument).toList();
    final activeSessions = sessions
        .where((session) => session.isActive)
        .toList();

    if (activeSessions.length > 1) {
      throw StateError(
        'Personal Fasting Activity has multiple active sessions',
      );
    }

    return PersonalFastingActivitySnapshot(
      activeSession: activeSessions.isEmpty ? null : activeSessions.single,
      endedSessions: sessions.where((session) => !session.isActive).toList(),
    );
  }

  @override
  Future<PersonalFastingActivitySnapshot> upsert(
    AppAccountId accountId,
    FastingSession session,
  ) async {
    final ownerAccountId = _ownerAccountIdFor(accountId);
    final sessionDocument = _fastingSessions(
      ownerAccountId,
    ).doc(session.id.value);
    final activityState = _activityState(ownerAccountId);

    await _firestore.runTransaction<void>((transaction) async {
      final stateDocument = await transaction.get(activityState);
      final persistedSessionDocument = await transaction.get(sessionDocument);
      final activeSessionId = _activeSessionIdFromState(stateDocument);
      final persistedSession = persistedSessionDocument.exists
          ? _sessionFromDocument(persistedSessionDocument)
          : null;

      if (session.isActive) {
        if (activeSessionId != null && activeSessionId != session.id.value) {
          throw StateError('Cannot upsert a second active Fasting Session');
        }
        if (persistedSession != null && !persistedSession.isActive) {
          throw StateError('Cannot reactivate an ended Fasting Session');
        }

        if (activeSessionId == null) {
          transaction.set(activityState, {'activeSessionId': session.id.value});
        }
      } else {
        if (persistedSession?.isActive == true &&
            activeSessionId != null &&
            activeSessionId != session.id.value) {
          throw StateError(
            'Personal Fasting Activity has multiple active sessions',
          );
        }

        if (activeSessionId == session.id.value) {
          transaction.delete(activityState);
        }
      }

      transaction.set(sessionDocument, _documentDataFor(session));
    });

    return loadSnapshot(ownerAccountId);
  }

  @override
  Future<PersonalFastingActivitySnapshot> deleteEndedSession(
    AppAccountId accountId,
    FastingSessionId id,
  ) async {
    final ownerAccountId = _ownerAccountIdFor(accountId);
    final sessionDocument = _fastingSessions(ownerAccountId).doc(id.value);
    final activityState = _activityState(ownerAccountId);

    await _firestore.runTransaction<void>((transaction) async {
      final stateDocument = await transaction.get(activityState);
      final persistedSessionDocument = await transaction.get(sessionDocument);
      final activeSessionId = _activeSessionIdFromState(stateDocument);
      if (!persistedSessionDocument.exists) {
        throw StateError('Cannot delete a missing ended Fasting Session');
      }

      final persistedSession = _sessionFromDocument(persistedSessionDocument);
      if (activeSessionId == id.value || persistedSession.isActive) {
        throw StateError('Cannot delete an active Fasting Session');
      }

      transaction.delete(sessionDocument);
    });

    return loadSnapshot(ownerAccountId);
  }

  AppAccountId _ownerAccountIdFor(AppAccountId requestedAccountId) {
    final authenticatedAccountId = _appAccountSession.accountId;
    if (requestedAccountId != authenticatedAccountId) {
      throw StateError(
        'Cannot access another App Account\'s Personal Fasting Activity',
      );
    }

    return authenticatedAccountId;
  }

  CollectionReference<Map<String, dynamic>> _fastingSessions(
    AppAccountId accountId,
  ) {
    return _firestore
        .collection('appAccounts')
        .doc(accountId.value)
        .collection('fastingSessions');
  }

  DocumentReference<Map<String, dynamic>> _activityState(
    AppAccountId accountId,
  ) {
    return _firestore
        .collection('appAccounts')
        .doc(accountId.value)
        .collection('personalFastingActivity')
        .doc('current');
  }
}

Map<String, Object> _documentDataFor(FastingSession session) {
  final data = <String, Object>{
    'startTime': Timestamp.fromDate(session.startTime),
    'targetEndTime': Timestamp.fromDate(session.targetEndTime),
  };
  final actualEndTime = session.actualEndTime;
  if (actualEndTime != null) {
    data['actualEndTime'] = Timestamp.fromDate(actualEndTime);
  }

  return data;
}

String? _activeSessionIdFromState(
  DocumentSnapshot<Map<String, dynamic>> document,
) {
  if (!document.exists) {
    return null;
  }

  final data = document.data();
  if (data == null ||
      data.keys.length != 1 ||
      data.keys.single != 'activeSessionId' ||
      data['activeSessionId'] is! String) {
    throw StateError('Invalid Personal Fasting Activity state');
  }

  return data['activeSessionId'] as String;
}

FastingSession _sessionFromDocument(
  DocumentSnapshot<Map<String, dynamic>> document,
) {
  final data = document.data();
  if (data == null) {
    throw StateError('Missing persisted Fasting Session ${document.id}');
  }

  final actualEndTime = data['actualEndTime'];
  final expectedFields = actualEndTime == null
      ? {'startTime', 'targetEndTime'}
      : {'startTime', 'targetEndTime', 'actualEndTime'};
  if (data.keys.toSet().length != expectedFields.length ||
      !data.keys.toSet().containsAll(expectedFields)) {
    throw StateError('Invalid persisted Fasting Session ${document.id}');
  }

  return FastingSession(
    id: FastingSessionId(document.id),
    startTime: _timestampFor(data, 'startTime', document.id),
    targetEndTime: _timestampFor(data, 'targetEndTime', document.id),
    actualEndTime: actualEndTime == null
        ? null
        : _timestampFor(data, 'actualEndTime', document.id),
  );
}

DateTime _timestampFor(
  Map<String, dynamic> data,
  String field,
  String sessionId,
) {
  final value = data[field];
  if (value is! Timestamp) {
    throw StateError('Invalid $field for persisted Fasting Session $sessionId');
  }

  return value.toDate().toUtc();
}
