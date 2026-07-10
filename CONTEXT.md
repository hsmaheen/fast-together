# Fasting App

A fasting support app for small private groups who want shared visibility into each other's fasting activity.

## Language

**Fasting Circle**:
A named private group of up to four members who can see each other's shared fasting activity. The creator chooses the initial name, and any Circle Member can edit it.
_Avoid_: Couple, chat group, feed

**Circle Member**:
A user who has joined a Fasting Circle and has consented to share fasting activity with the other members.
_Avoid_: Participant, group user

**Circle Membership**:
The relationship between a user and a Fasting Circle. The MVP allows up to five active Circle Memberships per user; a user's Shared Fasting Activity is visible to each circle only while the membership exists, without implying deletion of the user's personal fasting history. In the MVP, a Circle Member can leave by choice, but other members cannot remove them.
_Avoid_: User group, account group

**Join Request**:
A pending request created when someone uses a valid invitation to join a Fasting Circle; it must be approved by an existing Circle Member before the requester becomes a Circle Member, and it expires when the invitation expires.
_Avoid_: Signup, application

**Circle Invitation**:
A 24-hour invitation link or code created by a Circle Member that lets another user request to join a Fasting Circle.
_Avoid_: Permanent invite, access link

**Shared Fasting Activity**:
The fasting information automatically visible to other Circle Members: current fasting status, start time, target end time, elapsed fasting time, remaining time before the target end time, and over-target time after the target end time passes.
_Avoid_: Feed, diary, journal, full history

**Circle Status View**:
The circle view that shows all Circle Members, ordered with members who are currently Fasting before members who are Not Fasting; fasting members before the target end time are sorted by least remaining time first, over-target fasting members come after them, and not-fasting members are sorted by display name.
_Avoid_: Feed, leaderboard

**Personal Fasting Activity**:
A user's own fasting activity, available whether or not the user belongs to a Fasting Circle, including personal history such as recent sessions and calendar-based daily fasting totals. Users can delete ended Fasting Sessions from their personal history.
_Avoid_: Private feed, solo mode

**Fasting Status**:
A user's current fasting state, either Fasting or Not Fasting. Completion is an event, not a lasting status.
_Avoid_: Eating window, completed status

**Fasting Session**:
A period of fasting started by a user, with a user-set start time, target end time, and optional actual end time. A Fasting Session remains active until the user ends it, even after the target end time passes, records actual duration with minute precision, allows actual end time correction after it ends, requires start and actual end times not to be in the future, requires the actual end time to be after the start time, cannot be deleted while active, and a user can have only one active Fasting Session at a time.
_Avoid_: Timer, fast

**FastingSessionId**:
A stable, immutable identity for a Fasting Session that remains the same through ending, actual-end-time correction, and hydration.
_Avoid_: Timestamp, list position, result

**Fasting Result**:
The derived outcome of an ended Fasting Session, either Completed when the actual end time is at or after the target end time, or Ended Early when the actual end time is before the target end time.
_Avoid_: Success, failure

**Fasting Plan**:
The intended whole-hour duration for a Fasting Session, chosen from a preset duration of 10, 12, 14, 16, 18, 24, or 48 hours, or entered as a custom number of hours from 1 to 168.
_Avoid_: Timer preset, fasting type

**Circle Notification**:
An ephemeral event-based notification sent to Circle Members when another member starts or ends a Fasting Session. Circle Notifications are not a visible notification history or feed.
_Avoid_: Reminder, progress nudge, notification history

**Self Notification**:
A notification sent to the user who is fasting, limited in the MVP to halfway-through encouragement and target-end reached.
_Avoid_: Circle notification, progress nudge

**App Account**:
The user's authenticated identity in the app, created through Google Sign-In or Sign in with Apple for the MVP. A user can permanently delete their App Account, which removes their circle memberships, Member Profile, personal fasting history, and user-facing pending circle records.
_Avoid_: Login, profile

**Active Device**:
The single device currently allowed to use an App Account. In the MVP, signing in on a new device transfers the Active Device to that device and signs out the previous device.
_Avoid_: Device session, logged-in device

**Privacy Onboarding**:
The first-run explanation that joining a Fasting Circle shares current fasting status with Circle Members, personal history remains private, members can leave circles, users can delete their App Account, and the app is for tracking and support rather than medical advice.
_Avoid_: Marketing onboarding, tutorial

**Member Profile**:
The display identity visible to Circle Members, consisting of an editable display name and a profile image from the user's sign-in provider when available. The MVP lets users remove the provider profile image and fall back to a default image, but does not let users upload a replacement image.
_Avoid_: Account, bio
