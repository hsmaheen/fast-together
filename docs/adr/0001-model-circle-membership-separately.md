# Support multiple circle memberships

The MVP allows each user to belong to up to five Fasting Circles, so the app models Circle Membership as a relationship between a user and a Fasting Circle rather than storing a single circle directly on the user. This keeps circle sharing flexible while preserving a simple product rule: the user's Shared Fasting Activity is visible to every circle where they have an active membership.
