import 'package:fasting_app/data/firebase_emulator/firebase_emulator_configuration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the correct emulator host for each supported simulator', () {
    expect(
      FirebaseEmulatorHosts.forTarget(
        FirebaseEmulatorTarget.iosSimulator,
      ).authHost,
      '127.0.0.1',
    );
    expect(
      FirebaseEmulatorHosts.forTarget(
        FirebaseEmulatorTarget.androidEmulator,
      ).firestoreHost,
      '10.0.2.2',
    );
  });

  test('rejects remote hosts for the local-only emulator composition', () {
    expect(
      () => FirebaseEmulatorHosts(
        authHost: 'firebase.google.com',
        firestoreHost: 'firebase.google.com',
      ),
      throwsArgumentError,
    );
  });
}
