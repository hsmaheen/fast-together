# Use earned Flutter layers

The Flutter app will add top-level layers under `lib/` only when a real module earns them. Domain behavior lives in `lib/domain/`, application orchestration starts in `lib/application/`, UI code will be added under `lib/ui/` when real screens or view models exist, and data adapters will be added under `lib/data/` when persistence or Firebase integration exists. This follows Flutter's separation-of-concerns guidance while avoiding empty folders and premature architecture.
