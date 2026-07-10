enum FirebaseEmulatorTarget { iosSimulator, androidEmulator }

final class FirebaseEmulatorHosts {
  FirebaseEmulatorHosts({
    required this.authHost,
    required this.firestoreHost,
    this.authPort = 9099,
    this.firestorePort = 8080,
  }) {
    if (!_localHosts.contains(authHost) ||
        !_localHosts.contains(firestoreHost)) {
      throw ArgumentError.value(
        this,
        'hosts',
        'must point to a local iOS Simulator or Android Emulator host',
      );
    }
  }

  static const _localHosts = {'127.0.0.1', 'localhost', '10.0.2.2'};

  final String authHost;
  final String firestoreHost;
  final int authPort;
  final int firestorePort;

  static FirebaseEmulatorHosts forTarget(FirebaseEmulatorTarget target) {
    return switch (target) {
      FirebaseEmulatorTarget.iosSimulator => FirebaseEmulatorHosts(
        authHost: '127.0.0.1',
        firestoreHost: '127.0.0.1',
      ),
      FirebaseEmulatorTarget.androidEmulator => FirebaseEmulatorHosts(
        authHost: '10.0.2.2',
        firestoreHost: '10.0.2.2',
      ),
    };
  }
}
