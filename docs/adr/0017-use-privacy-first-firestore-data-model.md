# Use privacy-first Firestore data model

The Firebase backend will use a privacy-first Firestore model that keeps Personal Fasting Activity under owner-only paths and exposes only Shared Fasting Activity through circle-scoped projection documents. This deliberately duplicates the current fasting status into each Fasting Circle instead of letting Circle Members query a user's personal history, because the product promise is that personal fasting history stays private while current circle-visible activity is shared.

## Firestore Shape

- `appAccounts/{uid}`: owner-only App Account metadata such as Active Device state, deletion state, minimal settings, and non-analytics operational metadata.
- `memberProfiles/{uid}`: minimal Member Profile visible only to the owner and Circle Members who share an active Circle Membership with that user.
- `appAccounts/{uid}/fastingSessions/{sessionId}`: owner-only Personal Fasting Activity, including ended Fasting Sessions and correction history needed by the app.
- `fastingCircles/{circleId}`: Fasting Circle metadata such as name, member count, creation details, and update timestamps.
- `fastingCircles/{circleId}/members/{uid}`: Circle Membership records. Circle capacity and the user's five-circle membership limit are enforced when membership is created or approved.
- `fastingCircles/{circleId}/invitations/{invitationId}`: Circle Invitations with a 24-hour expiry.
- `fastingCircles/{circleId}/joinRequests/{requestId}`: Join Requests visible to the requester and existing Circle Members, expiring with the Circle Invitation.
- `fastingCircles/{circleId}/sharedFastingActivity/{uid}`: the only circle-readable fasting activity projection. It contains current Fasting Status, start time, target end time, the data needed to derive elapsed/remaining/over-target display values, and the update metadata needed for offline sync.
- Future notification records stay either ephemeral or user-scoped; they must not become a fasting timing analytics store.

## Security Rules Contract

- Use Firestore Security Rules version 2 and default-deny every path that is not explicitly matched.
- All client access requires Firebase Auth.
- Owner-only paths under `appAccounts/{uid}` require `request.auth.uid == uid`.
- Circle paths require an active Circle Membership document at `fastingCircles/{circleId}/members/{request.auth.uid}`.
- Shared Fasting Activity writes require `request.auth.uid == uid`, an active membership in the target Fasting Circle, and write metadata from the current Active Device.
- Personal Fasting Activity is never readable through a circle path; Circle Members read only `sharedFastingActivity`.
- Queries must be designed to satisfy rules up front. Rules are not filters, so every query shape must be constrained by path and required predicates rather than relying on rules to remove unauthorized documents.
- Client-owned writes that can be made offline include an `activeDeviceId` or equivalent write-device marker. Rules compare that marker with the current App Account Active Device so writes from a superseded device are rejected when they later sync.

## Account Deletion

App Account deletion will be handled by a trusted server-side deletion flow, not by recursive deletes from the Flutter client. The deletion flow removes the App Account, Member Profile, Personal Fasting Activity, Circle Membership records, Join Requests, active Circle Invitations created by the user, Shared Fasting Activity projections in every Fasting Circle, device tokens, and user-facing notification records. This is required because Firestore client deletion of collections/subcollections has security and performance problems, and deleting a document does not automatically delete its subcollections.

## Local Security Tests

Before implementing Firebase adapters or circle sharing UI, add Firebase Emulator Suite tests that prove:

- A user can read and write their own Personal Fasting Activity.
- A Circle Member can read another member's Shared Fasting Activity in the same Fasting Circle.
- A Circle Member cannot read another member's Personal Fasting Activity.
- A non-member cannot read circle metadata, members, Join Requests, or Shared Fasting Activity.
- Circle capacity is enforced at four members.
- A user cannot exceed five active Circle Memberships.
- Join Requests cannot be approved after invitation expiry.
- Writes from a superseded Active Device are rejected when they sync.
- Account deletion removes user-visible data from circles and private history.
- Observability captures crashes/errors without logging fasting timestamps as analytics events.

Use the Firestore rules unit testing APIs against the Local Emulator Suite, seed test data with rules disabled, clear emulator data between tests, and avoid relying on production Firebase for privacy verification.

## Sources Checked

- Firebase Security Rules guide: https://firebase.google.com/docs/firestore/security/get-started
- Firestore rules and queries: https://firebase.google.com/docs/firestore/security/rules-query
- Firestore data structuring guide: https://firebase.google.com/docs/firestore/manage-data/structure-data
- Firestore emulator guide: https://firebase.google.com/docs/emulator-suite/connect_firestore
- Firestore rules testing guide: https://firebase.google.com/docs/firestore/security/test-rules-emulator
- Firestore delete data guide: https://firebase.google.com/docs/firestore/manage-data/delete-data
