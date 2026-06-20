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
```
