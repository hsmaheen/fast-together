# Use UTC timestamps

Fasting timestamps will be treated as UTC instants in the domain model and persistence layer. The app will store fasting times in Firestore as `Timestamp` values, display and edit them in the user's local timezone, and use ISO-8601 UTC strings with a trailing `Z` only when a text representation is needed. This avoids mixing local timezone assumptions into fasting history, circle sharing, offline sync, and future backend adapters.
