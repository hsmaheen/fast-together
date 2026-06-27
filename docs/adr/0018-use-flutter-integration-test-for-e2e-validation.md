# Use Flutter integration_test for E2E validation

We will use Flutter's SDK `integration_test` package for programmatic E2E-style validation of composed app flows. Integration tests live under `integration_test/` and use the same `flutter_test` interaction APIs as widget tests, while exercising the real app composition rather than isolated components.

The first E2E tests should stay thin and journey-focused: prove that the app can start and end Fasting Sessions, show recent Personal Fasting Activity, delete ended Fasting Sessions, and validate custom Fasting Plan input. Component-level details remain covered by unit and widget tests.

When an epic includes behavior that cannot be reliably automated through Flutter widgets, the orchestrator will validate that behavior manually in the iOS simulator and create Linear bug tickets for any failures. `flutter drive` is reserved for target flows that require a driver process, such as future web/headless runs, instead of being the default mobile E2E path.
