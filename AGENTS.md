# Agent Instructions

This repository must be built in extremely small, test-driven increments.

## Required Context

Before changing code, read:

- `CONTEXT.md`
- `docs/MVP.md`
- `docs/decision-log.md`
- Relevant ADRs under `docs/adr/`

Use the domain language from `CONTEXT.md` in code, tests, commits, and explanations.

## Decision Tracking

- Record architectural decisions as ADRs in `docs/adr/`.
- Record durable product, domain, and process decisions in `docs/decision-log.md` when they do not need a full ADR.
- Keep `CONTEXT.md` as the current domain glossary, not a debate log.
- Keep `docs/MVP.md` as the current MVP scope, not a debate log.
- Use Linear comments for work-in-progress discussion, but summarize final durable decisions back into the repo.
- Do not rely on Git commits or Linear comments as the only record of a decision that future work must remember.

## Lightweight Domain-Driven Design

- Use DDD as language, behavior ownership, and boundary discipline.
- Keep domain rules close to the domain objects that own them.
- Prefer small, expressive domain types such as `FastingSession`, `FastingPlan`, and `FastingResult`.
- Add application use cases when orchestration becomes real, such as starting or ending a Fasting Session.
- Introduce repository interfaces only when persistence or multiple adapters make the seam real.
- Avoid DDD ceremony: no microservices, event sourcing, CQRS, large folder hierarchies, factories, or abstract repositories before the code earns them.
- If a new domain term appears, update `CONTEXT.md` in the same change.

## Strict TDD Rules

- Do not implement production behavior before a failing test exists.
- Work in vertical slices: one behavior, one failing test, minimal implementation, passing test.
- Do not write a batch of tests before implementation.
- Tests must verify observable behavior through public interfaces.
- Avoid tests that depend on private methods, internal structure, or incidental implementation details.
- Keep each change small enough to review comfortably.
- Do not add speculative fields, screens, services, abstractions, or dependencies for future features.
- Never refactor while tests are failing.
- After each green test, consider whether a small refactor is useful; skip it if the code is already clear.

## Preferred Build Order

Start with pure domain logic before UI or Firebase:

1. Fasting Session behavior in plain Dart.
2. Local Flutter state around that behavior.
3. Minimal UI for starting and ending a session.
4. Firebase adapters behind tested interfaces.
5. Circle sharing, invitations, notifications, and offline sync.

The first production component should be small enough to explain in one paragraph and test with a handful of behavior-focused tests.

## First Suggested Slice

Build a public `FastingSession` domain interface that can answer:

- whether a session is active
- elapsed duration at a given time
- remaining duration before the target end time
- over-target duration after the target end time
- completed vs ended-early result after an actual end time is set

Do not include Firebase, persistence, notifications, widgets, or animations in this slice.
