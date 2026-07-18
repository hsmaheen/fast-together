import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fasting_app/application/app_account_session.dart';
import 'package:fasting_app/application/personal_fasting_activity_repository.dart';
import 'package:fasting_app/data/firebase_emulator/firebase_emulator_configuration.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

const _demoProjectId = 'demo-fasting-app';
const _demoApiKey = 'AIzaSyD3moF4stingAppLocalOnly1234567890';
const _demoMessagingSenderId = '1234567890';
const _demoFirebaseOptionsForIos = FirebaseOptions(
  apiKey: _demoApiKey,
  appId: '1:1234567890:ios:1234567890abcdef',
  messagingSenderId: _demoMessagingSenderId,
  projectId: _demoProjectId,
);
const _demoFirebaseOptionsForAndroid = FirebaseOptions(
  apiKey: _demoApiKey,
  appId: '1:1234567890:android:1234567890abcdef',
  messagingSenderId: _demoMessagingSenderId,
  projectId: _demoProjectId,
);

/// Initializes the local-only Firebase Emulator Suite composition.
///
/// This root intentionally rejects an already initialized Firebase app: callers
/// must configure the Auth and Firestore emulators before using either client.
Future<AppAccountSessionProvider> initializeFirebaseEmulatorApp({
  FirebaseEmulatorHosts? hosts,
}) async {
  if (Firebase.apps.isNotEmpty) {
    throw StateError(
      'Firebase Emulator composition must initialize before any Firebase app',
    );
  }

  final emulatorHosts = hosts ?? _emulatorHostsForCurrentPlatform();

  await Firebase.initializeApp(
    options: _demoFirebaseOptionsForCurrentPlatform(),
  );

  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  await auth.useAuthEmulator(
    emulatorHosts.authHost,
    emulatorHosts.authPort,
    automaticHostMapping: false,
  );
  firestore.useFirestoreEmulator(
    emulatorHosts.firestoreHost,
    emulatorHosts.firestorePort,
    sslEnabled: false,
  );

  return _FirebaseEmulatorAppAccountSessionProvider(auth);
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
      'Firebase Emulator composition supports only iOS Simulator and Android Emulator',
    ),
  };
}

FirebaseOptions _demoFirebaseOptionsForCurrentPlatform() {
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => _demoFirebaseOptionsForIos,
    TargetPlatform.android => _demoFirebaseOptionsForAndroid,
    _ => throw UnsupportedError(
      'Firebase Emulator composition supports only iOS Simulator and Android Emulator',
    ),
  };
}

final class _FirebaseEmulatorAppAccountSessionProvider
    implements AppAccountSessionProvider {
  _FirebaseEmulatorAppAccountSessionProvider(this._auth);

  static const _email = 'flutter-emulator-app-account@demo-fasting-app.invalid';
  static const _password = 'local-emulator-only-password';

  final FirebaseAuth _auth;

  @override
  Future<AppAccountSession?> currentSession() async {
    final user = _auth.currentUser;
    return user == null ? null : _sessionForUser(user);
  }

  @override
  Future<AppAccountSession> signInOrCreateForLocalEmulator() async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: _email,
        password: _password,
      );
      return _sessionForUser(credential.user);
    } on FirebaseAuthException catch (error) {
      if (!_isMissingLocalEmulatorAccount(error)) {
        rethrow;
      }
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: _email,
        password: _password,
      );
      return _sessionForUser(credential.user);
    } on FirebaseAuthException catch (error) {
      if (error.code != 'email-already-in-use') {
        rethrow;
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: _email,
        password: _password,
      );
      return _sessionForUser(credential.user);
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

AppAccountSession _sessionForUser(User? user) {
  if (user == null) {
    throw StateError('Firebase Auth did not return an App Account identity');
  }

  return AppAccountSession(AppAccountId(user.uid));
}
