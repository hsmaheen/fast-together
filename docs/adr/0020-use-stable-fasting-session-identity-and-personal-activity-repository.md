# Use stable Fasting Session identity and a Personal Fasting Activity repository seam

Every Fasting Session has a required `FastingSessionId`. The domain model owns
that identity as an immutable value and carries it unchanged when a Fasting
Session ends or its actual end time is corrected. The application layer owns
new-ID creation through an injected generator in `FastingTracker`; the domain
does not create IDs from wall-clock time or Firebase code. The default local
generator produces opaque random IDs, while tests inject deterministic values.

Personal Fasting Activity is represented at the application seam by
`PersonalFastingActivitySnapshot`: one optional active Fasting Session plus
zero or more ended Fasting Sessions. This makes the at-most-one-active-session
invariant structural. Snapshot hydration rejects an ended value in the active
slot, an active value in ended history, and duplicate Fasting Session IDs.
Hydration preserves persisted IDs rather than assigning new ones.

Ended Fasting Sessions in a snapshot are ordered by actual end time descending,
with `FastingSessionId` lexical order as the deterministic tie-breaker. The
snapshot owns that normalization so callers and future adapters observe the
same newest-first Personal Fasting Activity ordering.

The application defines an account-scoped `PersonalFastingActivityRepository`
with three operations: load a snapshot, idempotently upsert a Fasting Session
by its ID, and delete an ended Fasting Session by ID. The contract accepts only
`AppAccountId`, `FastingSessionId`, Fasting Session, and snapshot values. It
does not expose Firebase Auth, Firestore, `Timestamp`, or adapter-specific
types. LIF-74 intentionally provides no repository adapter; a future
in-memory or Firestore adapter will satisfy this seam.

Repository writes are atomic per App Account. An active-session upsert replaces
the active Fasting Session only when it has the same `FastingSessionId`; an
active upsert with a different ID is rejected and leaves the snapshot unchanged.
An ended-session upsert replaces the matching ended session or transitions the
matching active session to ended. Deletion succeeds only for a matching ended
Fasting Session; attempts to delete the active session or a missing ID are
rejected. Each successful write returns the resulting validated snapshot.

`FastingResult` remains derived from a Fasting Session's target and actual end
times. It is not part of the snapshot or repository contract as persisted or
trusted state.

## Consequences

- Ending, correction, deletion, and hydration can refer to the same durable
  Fasting Session identity.
- Future persistence code has a small, account-scoped application interface
  while the domain and UI remain independent of Firebase representations.
- A malformed persisted snapshot fails at hydration instead of producing
  ambiguous local Personal Fasting Activity.
- An adapter must preserve the repository contract's ordering and idempotent
  upsert semantics, including atomic active-session conflict rejection and
  ended-only deletion; it must not persist `FastingResult` as authoritative
  data.
