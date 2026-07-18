# Use a demo-only FlutterFire emulator bootstrap

FlutterFire integration starts in a dedicated, local-only composition root.
The root initializes Firebase Core with explicit fictitious options for the
`demo-fasting-app` project, then connects Firebase Auth and Cloud Firestore to
the Emulator Suite before it performs an Auth or Firestore operation. It is not
called by the ordinary app composition.

The Flutter app depends only on Firebase Core, Firebase Auth, and Cloud
Firestore. It contains no `GoogleService-Info.plist`, `google-services.json`,
FlutterFire CLI configuration, production project ID, or production
credential. The options use values with the shapes required by the native SDKs,
but `demo-fasting-app` has no live resources, so an accidental non-emulated
request fails instead of reaching a production project.

## Emulator configuration

- The iOS Simulator connects to local emulators at `127.0.0.1`.
- The Android Emulator connects to the host machine at `10.0.2.2`.
- The Android debug network-security configuration permits cleartext traffic
  only to the `10.0.2.2` emulator host; release builds retain the platform
  default.
- Auth defaults to port `9099`; Firestore defaults to port `8080`.
- Callers may configure those local hosts and ports through
  `FirebaseEmulatorHosts`, but remote hosts are rejected.
- The root rejects an already initialized Firebase app. This makes emulator
  binding an ordering requirement instead of silently inheriting an unknown or
  production configuration.

Firebase Auth creates or signs in one deterministic local email/password App
Account for the emulator test flow. This is test plumbing only, not a
production sign-in provider. The production Google and Apple directions remain
defined by ADR 0003 and must get their own production configuration slice.

`signInOrCreateForLocalEmulator` always establishes that deterministic session
with the current Auth Emulator. It does not treat a cached Firebase Auth user
as proof that the restarted emulator still recognizes the account: it signs in
first and creates the account only when the emulator reports it absent. This
makes device credentials left by an earlier test run harmless after a fresh
Auth Emulator start.

## App Account seam and verification

Application callers receive `AppAccountSessionProvider`,
`AppAccountSession`, and `AppAccountId`; they never receive a Firebase Auth
`User`. Firebase types remain in the data adapter and device integration test.

The device-level test starts an Auth Emulator App Account and reads
`appAccounts/{uid}` with the real authenticated Firestore client and server
source. This verifies the owner-only read contract from ADR 0017 without
introducing Personal Fasting Activity persistence or changing Firebase-free
unit, widget, or local fasting integration tests.

The regression test clears Auth Emulator accounts while the device still has
the prior credential, then requires bootstrap to obtain a fresh token before
the owner-scoped Firestore read. This keeps the local adapter proof repeatable
across emulator restarts without adding production authentication behavior.

Current Firebase iOS SDK dependencies require iOS 15, so the iOS deployment
target is raised to 15.0. Android and iOS Simulator are the supported local
test targets; physical-device emulator routing is out of scope.

## Consequences

- Local FlutterFire validation can run against the same `demo-fasting-app`
  Auth and Firestore Emulator Suite as the rules harness.
- A production Firebase configuration cannot be added incidentally to this
  test bootstrap; it needs a separately reviewed composition root.
- Future Firestore adapters can use the App Account session seam without
  leaking Firebase users into domain or application code.
