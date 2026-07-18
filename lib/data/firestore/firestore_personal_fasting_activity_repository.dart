// Firebase construction parameter names are public; the SDK values stay private.
// ignore_for_file: prefer_initializing_formals

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fasting_app/application/app_account_session.dart';
import 'package:fasting_app/application/personal_fasting_activity_repository.dart';
import 'package:fasting_app/domain/fasting_session.dart';
import 'package:fasting_app/domain/fasting_session_id.dart';
import 'package:flutter/foundation.dart';

final class FirestorePersonalFastingActivityRepository
    implements PersonalFastingActivityRepository {
  FirestorePersonalFastingActivityRepository({
    required FirebaseFirestore firestore,
    required AppAccountSession appAccountSession,
    @visibleForTesting Future<void> Function()? afterFastingSessionsRead,
  }) : _firestore = firestore,
       _appAccountSession = appAccountSession,
       _afterFastingSessionsRead = afterFastingSessionsRead;

  final FirebaseFirestore _firestore;
  final AppAccountSession _appAccountSession;
  final Future<void> Function()? _afterFastingSessionsRead;

  @override
  Future<PersonalFastingActivitySnapshot> loadSnapshot(
    AppAccountId accountId,
  ) async {
    final ownerAccountId = _ownerAccountIdFor(accountId);
    return _loadSnapshot(ownerAccountId);
  }

  Future<PersonalFastingActivitySnapshot> _loadSnapshot(
    AppAccountId ownerAccountId,
  ) async {
    _ActivityStateMismatch? previousMismatch;
    for (var attempt = 0; attempt < _snapshotReadAttempts; attempt++) {
      final documents = await _fastingSessions(
        ownerAccountId,
      ).get(const GetOptions(source: Source.server));
      await _afterFastingSessionsRead?.call();
      final stateDocument = await _activityState(
        ownerAccountId,
      ).get(const GetOptions(source: Source.server));

      try {
        return _snapshotFromDocuments(documents, stateDocument);
      } on _ActivityStateMismatch catch (mismatch) {
        if (mismatch.fingerprint == previousMismatch?.fingerprint) {
          throw StateError(mismatch.message);
        }
        previousMismatch = mismatch;
      }
    }

    throw StateError('Could not read a consistent Personal Fasting Activity');
  }

  PersonalFastingActivitySnapshot _snapshotFromDocuments(
    QuerySnapshot<Map<String, dynamic>> documents,
    DocumentSnapshot<Map<String, dynamic>> stateDocument,
  ) {
    final sessions = documents.docs.map(_sessionFromDocument).toList();
    final activeSessions = sessions
        .where((session) => session.isActive)
        .toList();

    if (activeSessions.length > 1) {
      throw StateError(
        'Personal Fasting Activity has multiple active sessions',
      );
    }
    if (activeSessions.isNotEmpty && !stateDocument.exists) {
      throw _ActivityStateMismatch(
        'Active Fasting Session is missing its activity state',
        'active:${activeSessions.single.id.value};state:absent',
      );
    }
    if (activeSessions case [final activeSession]) {
      final activeSessionId = _activeSessionIdFromState(stateDocument);
      if (activeSessionId != activeSession.id.value) {
        throw _ActivityStateMismatch(
          'Activity state does not match the active Fasting Session',
          'active:${activeSession.id.value};state:$activeSessionId',
        );
      }
    }
    if (activeSessions.isEmpty && stateDocument.exists) {
      throw _ActivityStateMismatch(
        'Inactive Personal Fasting Activity has activity state',
        'active:absent;state:${_activeSessionIdFromState(stateDocument)}',
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
    await _loadSnapshot(ownerAccountId);
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
  Future<PersonalFastingActivitySnapshot> endActiveSession(
    AppAccountId accountId,
    FastingSession endedSession,
  ) async {
    if (endedSession.isActive) {
      throw ArgumentError.value(endedSession, 'endedSession', 'must be ended');
    }

    final ownerAccountId = _ownerAccountIdFor(accountId);
    await _loadSnapshot(ownerAccountId);
    final sessionDocument = _fastingSessions(
      ownerAccountId,
    ).doc(endedSession.id.value);
    final activityState = _activityState(ownerAccountId);

    await _firestore.runTransaction<void>((transaction) async {
      final stateDocument = await transaction.get(activityState);
      final persistedSessionDocument = await transaction.get(sessionDocument);
      final activeSessionId = _activeSessionIdFromState(stateDocument);
      final persistedSession = persistedSessionDocument.exists
          ? _sessionFromDocument(persistedSessionDocument)
          : null;

      if (activeSessionId == endedSession.id.value) {
        if (persistedSession == null ||
            !persistedSession.isActive ||
            !_sameLifecycle(persistedSession, endedSession)) {
          throw StateError('Durable active Fasting Session does not match');
        }

        transaction.delete(activityState);
        transaction.set(sessionDocument, _documentDataFor(endedSession));
        return;
      }

      if (activeSessionId == null &&
          persistedSession != null &&
          !persistedSession.isActive &&
          _sameSession(persistedSession, endedSession)) {
        return;
      }

      throw StateError('Cannot end a Fasting Session outside durable activity');
    });

    return loadSnapshot(ownerAccountId);
  }

  @override
  Future<PersonalFastingActivitySnapshot> correctEndedSession(
    AppAccountId accountId,
    FastingSession previousSession,
    FastingSession correctedSession,
  ) async {
    if (previousSession.isActive || correctedSession.isActive) {
      throw ArgumentError.value(
        correctedSession,
        'correctedSession',
        'must be ended',
      );
    }
    if (!_sameLifecycle(previousSession, correctedSession)) {
      throw ArgumentError.value(
        correctedSession,
        'correctedSession',
        'must preserve the stable ID and immutable session details',
      );
    }

    final ownerAccountId = _ownerAccountIdFor(accountId);
    await _loadSnapshot(ownerAccountId);
    final sessionDocument = _fastingSessions(
      ownerAccountId,
    ).doc(previousSession.id.value);
    final activityState = _activityState(ownerAccountId);

    await _firestore.runTransaction<void>((transaction) async {
      final stateDocument = await transaction.get(activityState);
      final persistedSessionDocument = await transaction.get(sessionDocument);
      if (!persistedSessionDocument.exists) {
        throw StateError('Cannot correct a missing ended Fasting Session');
      }

      final persistedSession = _sessionFromDocument(persistedSessionDocument);
      if (persistedSession.isActive ||
          _activeSessionIdFromState(stateDocument) ==
              previousSession.id.value) {
        throw StateError('Cannot correct an active Fasting Session');
      }
      if (!_sameSession(persistedSession, previousSession)) {
        throw StateError(
          'Cannot correct a Fasting Session outside its durable prior state',
        );
      }
      if (_sameSession(persistedSession, correctedSession)) {
        return;
      }

      transaction.set(sessionDocument, _documentDataFor(correctedSession));
    });

    return loadSnapshot(ownerAccountId);
  }

  @override
  Future<PersonalFastingActivitySnapshot> deleteExactEndedSession(
    AppAccountId accountId,
    FastingSession expectedSession,
  ) async {
    if (expectedSession.isActive) {
      throw ArgumentError.value(
        expectedSession,
        'expectedSession',
        'must be ended',
      );
    }

    final ownerAccountId = _ownerAccountIdFor(accountId);
    await _loadSnapshot(ownerAccountId);
    final sessionDocument = _fastingSessions(
      ownerAccountId,
    ).doc(expectedSession.id.value);
    final activityState = _activityState(ownerAccountId);

    await _firestore.runTransaction<void>((transaction) async {
      final stateDocument = await transaction.get(activityState);
      final persistedSessionDocument = await transaction.get(sessionDocument);
      if (!persistedSessionDocument.exists) {
        throw StateError('Cannot delete a missing ended Fasting Session');
      }

      final persistedSession = _sessionFromDocument(persistedSessionDocument);
      if (persistedSession.isActive ||
          _activeSessionIdFromState(stateDocument) ==
              expectedSession.id.value) {
        throw StateError('Cannot delete an active Fasting Session');
      }
      if (!_sameSession(persistedSession, expectedSession)) {
        throw StateError(
          'Cannot delete a Fasting Session outside its durable prior state',
        );
      }

      transaction.delete(sessionDocument);
    });

    return loadSnapshot(ownerAccountId);
  }

  @override
  Future<PersonalFastingActivitySnapshot> deleteEndedSession(
    AppAccountId accountId,
    FastingSessionId id,
  ) async {
    final ownerAccountId = _ownerAccountIdFor(accountId);
    await _loadSnapshot(ownerAccountId);
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

const _snapshotReadAttempts = 3;

final class _ActivityStateMismatch implements Exception {
  const _ActivityStateMismatch(this.message, this.fingerprint);

  final String message;
  final String fingerprint;
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

bool _sameSession(FastingSession left, FastingSession right) {
  return _sameLifecycle(left, right) &&
      left.actualEndTime == right.actualEndTime;
}

bool _sameLifecycle(FastingSession left, FastingSession right) {
  return left.id == right.id &&
      left.startTime == right.startTime &&
      left.targetEndTime == right.targetEndTime;
}
