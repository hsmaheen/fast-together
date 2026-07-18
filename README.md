# Fasting App

A mobile-first fasting tracker for personal fasting and optional Fasting Circle sharing.

## Development

Read these before changing code:

- `AGENTS.md`
- `CONTEXT.md`
- `docs/MVP.md`
- relevant ADRs under `docs/adr/`

This project is built in small, test-driven slices. Start with the domain model, keep behavior behind public interfaces, and avoid adding Firebase or UI code before the current slice earns it.

Useful commands:

```sh
flutter test
flutter analyze
flutter run -d <device-id>
npm ci
PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH" JAVA_HOME=/opt/homebrew/opt/openjdk@21 npm run test:rules
firebase emulators:start --project demo-fasting-app --only auth,firestore
```

## Firebase Emulator Suite

The Firebase rules harness uses the local project ID `demo-fasting-app`; it does
not require a production Firebase project.

Prerequisites:

- Node.js and npm.
- A local Java runtime on `PATH`, required by the Firestore emulator.

On macOS with Homebrew, OpenJDK 21 can be used without linking it into the
system Java wrappers:

```sh
brew install openjdk@21
export JAVA_HOME=/opt/homebrew/opt/openjdk@21
export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"
```

Install the Node dependencies once:

```sh
npm ci
```

Run the Firestore rules tests through the emulator:

```sh
PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH" JAVA_HOME=/opt/homebrew/opt/openjdk@21 npm run test:rules
```

Start the Auth and Firestore emulators for manual local development:

```sh
firebase emulators:start --project demo-fasting-app --only auth,firestore
```

## FlutterFire Emulator Bootstrap

The FlutterFire bootstrap is intentionally a device-level emulator test root. It
uses explicit, fictitious `demo-fasting-app` options rather than
`GoogleService-Info.plist`, `google-services.json`, or a FlutterFire CLI
configuration file. The ordinary `flutter run`, domain, application, widget,
and local fasting integration paths do not initialize Firebase.

With the Auth and Firestore emulators running, list available devices and run
the bootstrap proof on an iOS Simulator or Android Emulator:

```sh
flutter devices
flutter test integration_test/firebase_emulator_app_account_bootstrap_test.dart -d <device-id>
flutter test integration_test/personal_fasting_activity_firestore_adapter_test.dart -d <device-id>
```

The composition root connects both clients before any Auth or Firestore
operation. Its default routes are `127.0.0.1` for the iOS Simulator and
`10.0.2.2` for the Android Emulator. `FirebaseEmulatorHosts` can configure the
local host and ports for either route, but rejects remote hosts so this root
cannot be pointed at a production service. Physical-device routing and
production Google or Apple sign-in are not part of this bootstrap.

On Android, the debug network-security configuration permits cleartext traffic
only to the `10.0.2.2` Auth and Firestore emulator host. Release builds retain
the default platform network policy.
