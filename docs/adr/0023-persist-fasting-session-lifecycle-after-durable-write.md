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

An active-start failure also retains the exact attempted Fasting Session and
the originating App Account ID in the failure outcome. This preserves its
generated stable ID without presenting it as local durable state or making the
command portable between accounts. `retryStart` first confirms that the
currently authenticated App Account is the originating one. A different
account is rejected before the repository is read or written. For the same
account, it then reads the durable snapshot: an exact durable active session
reconciles successfully without another write; a different active or an ended
session with that ID is rejected; an absent ID is replayed with the same stable
ID. This covers an acknowledgement that is lost after the Firestore transaction
has already committed, without fabricating a second active session, writing the
session into another owner path, or claiming durability on the failed attempt.

Ending is anchored to the durable active Fasting Session rather than solely to
the caller's tracker. The application service loads the account snapshot,
requires the local active session to have the exact same ID and immutable start
details, and asks the repository to atomically end that active ID. The
repository accepts an exact already-ended value as a retry, but rejects a
different active ID, changed immutable details, or changed actual end time. A
changed actual end time is a correction and remains LIF-79 scope. These checks
make a stale tracker an explicit failure with no local replacement and prevent
a stale end from becoming unrelated history beside a newer active session.

An exact repeated start is idempotent when the existing active Fasting Session
has the same start and target end times. An exact repeated end is idempotent
only when the durable ended Fasting Session has the same stable ID, immutable
start details, and actual end time. A different end time is an actual-end-time
correction, so it is rejected by this tracer bullet and remains LIF-79 scope.

## Consequences

- A Fasting Session's stable ID is generated once by `FastingTracker`, then is
  preserved through the active and ended upserts of the same Firestore
  document.
- `PersonalFastingActivityRepository.endActiveSession` is a narrow atomic
  transition contract. Generic upsert remains available for the existing
  repository seam, but this lifecycle use case does not use it to write an
  ended historical session.
- A second active start is rejected before a replacement tracker is exposed;
  repository conflict rejection is also returned as a non-durable outcome.
- Ordinary application, widget, and local fasting tests stay Firebase-free by
  exercising the repository seam with fakes.
- The live Flutter emulator test proves the authenticated Firestore adapter can
  persist a start, persist an end, reconstruct the tracker, and restore ended
  Personal Fasting Activity.
- Corrections, deletions, offline synchronization, and UI wiring are not part
  of this lifecycle slice.
