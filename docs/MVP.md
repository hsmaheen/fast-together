# MVP

The MVP is a mobile-first fasting tracker for iOS and Android. A user can track fasting personally, optionally share current fasting status with small private groups, and retain control over privacy through leaving circles and deleting their account.

## Product Scope

- Users can sign in with Google Sign-In or Sign in with Apple.
- The MVP is English-only.
- Users can track fasting without joining a Fasting Circle.
- Users can create and join named Fasting Circles.
- Any Circle Member can edit the circle name.
- A Fasting Circle has up to four members.
- A user can belong to up to five Fasting Circles.
- Joining a Fasting Circle is consent to share current fasting activity with that circle.
- Users can leave circles, but members cannot remove other members in the MVP.
- Users can permanently delete their account.

## Fasting

- A user can have one active Fasting Session at a time.
- The user chooses a Fasting Plan from 10, 12, 14, 16, 18, 24, or 48 hours, or enters a custom whole-hour duration from 1 to 168 hours.
- The start time is user-set, so a user can start now while recording that the fast began earlier.
- The target end time is a goal, not an automatic stop.
- The session remains active until the user ends it.
- When ending a session, the user can set the actual end time.
- The actual end time of an ended session can be corrected later.
- Active sessions cannot be deleted; ended sessions can be deleted from personal history.
- Actual duration is recorded and displayed with minute precision.
- Fasting Result is derived from the times: Completed if actual end time is at or after target end time, otherwise Ended Early.

## Circle Sharing

- Circle Members see each other's current Fasting Status.
- Shared Fasting Activity includes current status, start time, target end time, elapsed fasting time, remaining time before the target end time, and over-target time after the target end time passes.
- Personal fasting history is private in the MVP.
- If a member is Not Fasting, other members simply see Not Fasting.
- Circle Status View shows fasting members first, sorted by least remaining time before the target end time; over-target fasting members come after them, followed by not-fasting members sorted by display name.

## Invitations

- A Circle Member can create a Circle Invitation.
- Circle Invitations are valid for 24 hours.
- Using an invitation creates a Join Request.
- Join Requests expire when the Circle Invitation expires.
- Any existing Circle Member can approve a Join Request.
- Circle capacity and the requester's five-circle membership limit are checked when creating and approving a Join Request.
- If the circle already has four members, the app prevents requesting or approving membership and shows that the circle is full.
- If the requester already belongs to five circles, the app prevents requesting or approving membership and shows that the user has reached the circle limit.

## Profiles

- Member Profiles include an editable display name.
- Profile images come from Google or Apple when available.
- Users can remove the provider profile image and use a default image.
- Users cannot upload replacement profile images in the MVP.

## Notifications

- Circle Notifications are ephemeral and sent when another Circle Member starts or ends a Fasting Session.
- The MVP does not include a visible notification history or feed.
- Self Notifications are sent halfway through the user's fast and when the target end time is reached.
- No hourly progress reminders are included.

## History

- Users can see their own fasting history.
- The MVP should support a recent-history view and calendar-based daily fasting totals.
- Streaks, achievements, health journaling, exports, and payments are out of scope.

## Privacy

- Privacy Onboarding explains that circle membership shares current fasting status, personal history is private, users can leave circles, and users can delete their account.
- The app includes a simple disclaimer that it is for tracking and support, not medical advice.
- Account deletion removes circle memberships, Member Profile, personal fasting history, pending join requests, active invitations created by the user, and user-facing notification records.

## Technical Direction

- Flutter for iOS and Android.
- Firebase Auth for Google and Apple sign-in.
- Cloud Firestore for app data.
- Firebase Cloud Messaging for notifications.
- Firebase Emulator Suite for local development and testing.
- Fasting timestamps are stored and handled as UTC instants; the UI displays and edits them in the user's local timezone.
- Local development uses the official Flutter and Firebase CLI commands directly; a wrapper command can be added later if the workflow becomes repetitive.
- The MVP is mobile-first: iOS and Android are supported, web is optional and not guaranteed, desktop is out of scope.
- Core fasting actions should work offline and sync later.
- If offline edits conflict, the last edit wins.
- Only one Active Device is allowed per App Account; signing in on a new device transfers the Active Device and signs out the previous device.
- Offline writes from a superseded Active Device are rejected when they try to sync.
- Use crash reporting, but keep analytics minimal and avoid capturing sensitive fasting timing data.
