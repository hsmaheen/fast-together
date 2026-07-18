import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fasting_app/application/app_account_session.dart';
import 'package:fasting_app/data/firebase_emulator/firebase_emulator_app.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    're-establishes an Auth Emulator App Account after its cached credentials become stale',
    (tester) async {
      final appAccountSessions = await initializeFirebaseEmulatorApp();
      final initialSession = await appAccountSessions
          .signInOrCreateForLocalEmulator();

      expect(initialSession.accountId.value, isNotEmpty);

      await _readOwnerScopedFirestoreDocument(initialSession);
      await _clearAuthEmulatorAccounts();

      final cachedSession = await appAccountSessions.currentSession();

      expect(cachedSession?.accountId, initialSession.accountId);

      final reauthenticatedSession = await appAccountSessions
          .signInOrCreateForLocalEmulator();

      expect(reauthenticatedSession.accountId.value, isNotEmpty);
      final refreshedToken = await FirebaseAuth.instance.currentUser!
          .getIdToken(true);

      expect(refreshedToken, isNotEmpty);
      await _readOwnerScopedFirestoreDocument(reauthenticatedSession);
    },
  );
}

Future<void> _readOwnerScopedFirestoreDocument(
  AppAccountSession session,
) async {
  final appAccountDocument = await FirebaseFirestore.instance
      .collection('appAccounts')
      .doc(session.accountId.value)
      .get(const GetOptions(source: Source.server));

  expect(appAccountDocument.id, session.accountId.value);
}

Future<void> _clearAuthEmulatorAccounts() async {
  final client = HttpClient();
  try {
    final request = await client.deleteUrl(
      Uri(
        scheme: 'http',
        host: _authEmulatorHost,
        port: 9099,
        path: '/emulator/v1/projects/demo-fasting-app/accounts',
      ),
    );
    final response = await request.close();
    await response.drain();

    if (response.statusCode != HttpStatus.ok) {
      throw StateError('Could not clear the Auth Emulator accounts');
    }
  } finally {
    client.close(force: true);
  }
}

String get _authEmulatorHost => switch (defaultTargetPlatform) {
  TargetPlatform.android => '10.0.2.2',
  TargetPlatform.iOS => '127.0.0.1',
  _ => throw UnsupportedError('Firebase Emulator tests require a simulator'),
};
