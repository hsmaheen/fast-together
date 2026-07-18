# Persist ended Fasting Session corrections and deletions by exact durable state

LIF-79 adds a dedicated application module for changing an ended Fasting
Session after it has been restored into a `FastingTracker`. It prepares a
replacement tracker, but only exposes it after the account-scoped
`PersonalFastingActivityRepository` returns a validated durable snapshot.
Failed validation or persistence returns a mutation failure that retains the
original tracker, so the caller never presents a non-durable correction or
deletion as restored Personal Fasting Activity.

The repository now has narrow atomic operations for a correction and an ended
deletion. A correction accepts a complete `previousSession` and
`correctedSession`; both must be ended, have the same stable ID, start time,
and target end time, and the durable document must exactly match the previous
session. The Firestore adapter updates that existing document at
`appAccounts/{uid}/fastingSessions/{sessionId}` in a transaction. It never
uses generic upsert for a correction, so it cannot create a missing document,
change the document identity, or modify immutable session details.

An ended deletion similarly accepts the complete expected durable session. It
deletes only that document when its complete ended value still matches. Missing
and active IDs, or a session corrected by another client after hydration, are
explicit failures. A direct repeated deletion is therefore rejected according
to the repository contract; only the application retry path treats an absent
document as a successful reconciliation when a prior deletion acknowledgement
was lost.

Correction and deletion retry attempts retain their originating App Account
identity and exact expected state. A retry for another account fails before a
repository read or write. A same-account correction first loads durable
activity and treats the exact corrected value as a recovered acknowledgement;
a same-account deletion treats an absent ID as recovered acknowledgement. Any
other durable value is a stale operation and is rejected rather than replayed.

## Consequences

- A correction preserves one stable `FastingSessionId` and one Firestore
  document path while allowing only `actualEndTime` to change.
- Correction and deletion races become explicit application outcomes instead
  of arbitrary history upserts or unrelated deletes.
- The tracker is rebuilt from the durable snapshot after every successful
  mutation, so recent history and calendar-day totals follow the corrected or
  deleted restored data.
- Firebase remains behind the repository seam. Firebase-free application tests
  exercise failure, retry, account-bound, and history behavior; a device test
  proves the authenticated emulator journey and owner isolation.
- Offline synchronization, UI wiring, production sign-in, Circle behavior,
  invitations, and notifications remain out of scope.
