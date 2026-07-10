# Use trusted transactions for Circle Membership limits

Circle Membership lifecycle writes will cross a trusted server boundary. Mobile clients can read the Circle Membership records for a Fasting Circle they belong to, but Firestore rules deny direct client creates, updates, and deletes for membership records and their denormalized limit state. This keeps membership consent, capacity, and cleanup in one transactional write path instead of trusting offline clients to coordinate security-sensitive counters.

## Firestore shape and invariants

- `fastingCircles/{circleId}` stores `memberCount`, which must stay between one and four. Trusted circle creation and Circle Membership transactions own this field; a Circle Member name edit cannot change it.
- `fastingCircles/{circleId}/members/{uid}` is the authoritative active Circle Membership edge. Existence means the membership is active; there is no client-editable status field.
- `appAccounts/{uid}/circleMembershipState/current` stores the unique `circleIds` for the App Account, with at most five entries. The owner can read this document to discover the known circle document paths, but cannot write it directly.
- A trusted Circle Membership transaction reads the circle, membership edge, and App Account membership state; rejects a create when `memberCount` is four or `circleIds` already has five entries; and writes the edge, count, and index atomically. Leaves and account deletion use the inverse transaction so the edge, count, index, and Shared Fasting Activity projection do not diverge.

Firestore rules cannot count arbitrary subcollection documents, and Admin SDK writes bypass rules. The trusted transaction is therefore part of the security contract: every privileged membership writer must preserve the four-member and five-membership limits. Firestore transactions provide the concurrency boundary so simultaneous approvals cannot both consume the last capacity slot. Rules tests seed trusted state with rules disabled and prove clients cannot bypass the boundary by changing a membership edge, `memberCount`, or membership index.

This ADR defines the membership transaction contract but does not implement Circle Invitations, Join Requests, approval UI, or leave UI. Those workflows must call the trusted transaction when their scoped issues are implemented.

## Shared Fasting Activity projection

`fastingCircles/{circleId}/sharedFastingActivity/{uid}` remains one current-status projection per Circle Member, not a history collection. Only the member identified by `{uid}` can create or replace it, only while they belong to the circle, and the write must carry the current App Account Active Device marker.

- `Not Fasting` stores only `status`, `activeDeviceId`, and `updatedAt`.
- `Fasting` additionally stores UTC `startedAt` and `targetEndedAt`, with the target after the start.
- Elapsed, remaining, and over-target values are derived from `startedAt`, `targetEndedAt`, and the application clock. Persisting those changing values, an actual end time, session results, or any other history field is denied.

Circle Members can list this circle-scoped projection collection because access depends on their membership in that known Fasting Circle. An App Account discovers its known circle IDs from its owner-only membership index and then reads each circle by document path; a global Fasting Circle collection query is not part of the contract because Firestore rules are not filters. Personal Fasting Activity stays only at `appAccounts/{uid}/fastingSessions/{sessionId}` and remains owner-only.

## Consequences

- Limit enforcement is safe against client tampering and concurrent trusted membership writes when every privileged writer uses the transaction contract.
- A privileged script or future backend that writes membership documents outside the transaction can violate the invariant because rules cannot constrain Admin SDK access; code review and risk-based emulator tests must treat that as a security defect.
- The denormalized count and index add coordination work to membership changes, but they provide deterministic limit checks and queryable known-circle paths without exposing all Fasting Circles.
