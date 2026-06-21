# Use application clock for Fasting Session action time validation

Fasting actions that depend on the current time will be validated in the application layer with an injected UTC clock. `FastingTracker` owns checks that a user-set start time, actual end time, or corrected actual end time is not in the future.

The domain model still owns timeless Fasting Session invariants, such as UTC timestamps, target end after start, actual end after start, active vs ended state, and derived Fasting Result. This keeps domain behavior deterministic without coupling immutable domain objects to wall-clock time, while keeping application tests deterministic through a fixed clock.
