# Persist Fasting Session lifecycle after a durable repository write

LIF-78 introduces `PersistFastingSessionTransitions` as the application
module for the Fasting Session start and end lifecycle. It accepts a current
`FastingTracker`, prepares a replacement tracker, and writes the proposed
Fasting Session through the account-scoped `PersonalFastingActivityRepository`.
Only a successful repository upsert yields a
`PersistedFastingSessionTransition`, whose tracker is rebuilt from the
repository's returned validated snapshot.

A failed validation, missing App Account session, or repository write returns
`FastingSessionTransitionFailure`. That outcome exposes the original tracker
and the error. Callers must keep using the original tracker unless they receive
the persisted outcome. This is deliberately not described as a distributed
rollback: the local tracker has not changed, and the repository owns the
atomic durable mutation described by ADR 0020 and ADR 0022.

An exact repeated start is idempotent when the existing active Fasting Session
has the same start and target end times. An exact repeated end is idempotent
only for the newest ended Fasting Session with the same actual end time. A
different end time is an actual-end-time correction, so it is rejected by this
tracer bullet and remains LIF-79 scope.

## Consequences

- A Fasting Session's stable ID is generated once by `FastingTracker`, then is
  preserved through the active and ended upserts of the same Firestore
  document.
- A second active start is rejected before a replacement tracker is exposed;
  repository conflict rejection is also returned as a non-durable outcome.
- Ordinary application, widget, and local fasting tests stay Firebase-free by
  exercising the repository seam with fakes.
- The live Flutter emulator test proves the authenticated Firestore adapter can
  persist a start, persist an end, reconstruct the tracker, and restore ended
  Personal Fasting Activity.
- Corrections, deletions, offline synchronization, and UI wiring are not part
  of this lifecycle slice.
