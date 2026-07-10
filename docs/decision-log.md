# Decision Log

This log captures durable product, domain, and process decisions that do not need a full ADR.

Use this file for choices that future work should remember, but that do not reshape the architecture. Use ADRs in `docs/adr/` for decisions that affect system structure, dependencies, interfaces, persistence, testing architecture, deployment, security, or other hard-to-reverse technical constraints.

Keep current product truth in `docs/MVP.md` and current domain language in `CONTEXT.md`. Keep Linear comments for work-in-progress discussion. Keep Git commits for implementation history. Add a `CHANGELOG.md` later when release/user-visible changes need tracking.

## When To Write What

| Decision type | Home |
| --- | --- |
| Architecture, dependency, interface, persistence, deployment, or testing architecture | ADR in `docs/adr/` |
| Product scope, domain rule, workflow/process, naming choice, or deferred feature rationale | This decision log |
| Current domain vocabulary | `CONTEXT.md` |
| Current MVP behavior/scope | `docs/MVP.md` |
| Issue-level discussion and implementation notes | Linear issue comments |
| User-visible release changes | Future `CHANGELOG.md` |

## Template

```md
## YYYY-MM-DD - Decision title

Decision: We will ...
Reason: Because ...
Scope: Product | Domain | Process
Status: Accepted
Links: ADR/Linear issue/commit
```

## 2026-06-20 - Use layered decision tracking

Decision: We will use ADRs for architectural decisions and this decision log for durable product, domain, and process decisions that do not need a full ADR.
Reason: ADRs are valuable for high-impact technical rationale, but using them for every product or workflow choice would create noise. A small decision log preserves context without making every discussion ceremonial.
Scope: Process
Status: Accepted
Links: `docs/adr/`, `CONTEXT.md`, `docs/MVP.md`

## 2026-06-21 - Visualize UI with disposable HTML prototypes before Flutter implementation

Decision: We will use Impeccable to shape UI work and create small disposable HTML/CSS prototypes for important screens before building the production Flutter version.
Reason: HTML prototypes let us compare layout, hierarchy, color, copy, and motion directions quickly without committing production Flutter code too early. After a direction is chosen, the production Flutter implementation still follows the repo's strict TDD process.
Scope: Process
Status: Accepted
Links: `PRODUCT.md` and `DESIGN.md` once created

## 2026-06-21 - Use a warm natural premium color direction

Decision: We will steer the visual design toward warm, welcoming, intimate, soft, premium, autumnal, and natural colors.
Reason: This better matches the desired emotional tone than the earlier cool cobalt exploration. Warmth should still be restrained and intentional, avoiding clinical health UI, gamified color, overly colorful surfaces, and generic beige wellness branding.
Scope: Product
Status: Accepted
Links: `PRODUCT.md`, `DESIGN.md`, `/Users/maheen/Downloads/material-theme.json`, `/Users/maheen/Downloads/materialkolor-theme.zip`

## ADR Index

- `0001` - Model circle membership separately
- `0002` - Defer manual past-session creation
- `0003` - Support Google and Apple sign-in
- `0004` - Defer streaks
- `0005` - Exclude health journaling
- `0006` - Support offline fast changes
- `0007` - Enforce one active device per account
- `0008` - Make account deletion core
- `0009` - Use Flutter and Firebase
- `0010` - Use mobile-first platform scope
- `0011` - Use minimal observability
- `0012` - Defer payments
- `0013` - Use lightweight Domain-Driven Design
- `0014` - Use UTC timestamps
- `0015` - Use earned Flutter layers
- `0016` - Use application clock for Fasting Session action time validation
- `0017` - Use privacy-first Firestore data model
- `0018` - Use Flutter integration_test for E2E validation
- `0019` - Use trusted transactions for Circle Membership limits
