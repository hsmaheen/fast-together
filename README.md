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
flutter run
npm install
npm run test:rules
npm run emulators:start
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
npm install
```

Run the Firestore rules tests through the emulator:

```sh
npm run test:rules
```

Start the Auth and Firestore emulators for manual local development:

```sh
npm run emulators:start
```
