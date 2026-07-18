# Use an active-session sentinel for Personal Fasting Activity

LIF-76 stores each Personal Fasting Activity Fasting Session at
`appAccounts/{uid}/fastingSessions/{sessionId}`. The document ID is the stable
`FastingSessionId`; session documents do not repeat it in a field.

The canonical document shape is deliberately small:

- An active Fasting Session has `startTime` and `targetEndTime` Firestore
  `Timestamp` fields.
- An ended Fasting Session additionally has `actualEndTime` as a Firestore
  `Timestamp`.
- Every timestamp is hydrated as UTC.
- `FastingResult` is derived from those timestamps and is never persisted or
  trusted as state.

Firestore's Flutter transaction API can atomically read individual documents,
but cannot read a collection query inside a transaction. Therefore the adapter
also owns `appAccounts/{uid}/personalFastingActivity/current`. When an active
Fasting Session exists, this private owner-only sentinel contains exactly its
`activeSessionId`; it is absent otherwise.

Every server-source snapshot read validates the sentinel with the hydrated
sessions: no active Fasting Session requires no sentinel; one active Fasting
Session requires the exact one-field sentinel naming that session. A missing,
stale, mismatched, or malformed sentinel is corrupted Personal Fasting
Activity and is rejected. The adapter does not silently repair it.

The Flutter Firestore client cannot include the collection query in a
transaction, so the session query and sentinel read are separate server
operations. A valid active-to-ended transaction may commit between them and
temporarily produce a mismatched pair. The adapter therefore retries only a
sentinel/session mismatch with fresh full server observations, up to three
attempts. A repeated observed relationship is stable corruption and is
rejected; malformed session or sentinel documents are rejected immediately.
The same validated read is used for mutation preflight, so a valid transition
between its reads does not reject the requested write.

## Transaction semantics

Each repository write first verifies that the requested `AppAccountId` is the
authenticated `AppAccountSession` identity. Callers therefore cannot choose a
different account path. It performs the validated snapshot read before opening
a transaction, so corrupted legacy state is rejected before a write can mutate
Personal Fasting Activity.

An active-session upsert reads the sentinel and its target document. It creates
the sentinel when none exists, permits a repeat for the same ID, and rejects a
different active ID without writing. It also rejects reactivation of an ended
session. An ended-session upsert transitions a matching active session by
writing the ended document and deleting the sentinel in one transaction, or
updates an already-ended document by ID. An ended-session delete reads both
documents and rejects a missing or active ID before deleting the ended document.
Rejected operations leave the persisted snapshot unchanged.

The Firestore rules validate the exact document shapes with `getAfter`. They
require a matching sentinel whenever an active session is written and require
that the sentinel no longer points to a session that is ended or deleted. This
keeps the one-active-session invariant intact for direct clients as well as the
adapter. Successful mutations then load a server-source snapshot, whose public
constructor validates unique IDs, one active session, and deterministic ended
history ordering.

## Consequences

- The concrete adapter fulfills the atomic/rejection contract established by
  ADR 0020 without leaking Firebase types into domain or application code.
- Transactional persistence requires a reachable Firestore server. Offline
  synchronization is still explicitly out of scope for this MVP slice.
- The former JavaScript ended-session repository used a conflicting schema and
  is retired. The Firestore rules harness now writes the Flutter canonical
  schema directly.
- Owner save/load/delete, idempotency, and rule enforcement are verified with
  a real authenticated Auth and Firestore Emulator client in Flutter device
  integration tests.
