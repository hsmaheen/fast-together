<!-- SEED: re-run $impeccable document once there's code to capture the actual tokens and components. -->
---
name: Fasting App
description: Warm private fasting support for couples and small trusted circles.
colors:
  bg: "oklch(1.000 0.000 0)"
  surface: "oklch(0.965 0.018 75)"
  surface-raised: "oklch(0.985 0.010 75)"
  ink: "oklch(0.220 0.025 70)"
  muted: "oklch(0.430 0.020 70)"
  primary: "oklch(0.430 0.070 65)"
  primary-soft: "oklch(0.900 0.045 70)"
  accent: "oklch(0.560 0.085 35)"
typography:
  display:
    fontFamily: "system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif"
    fontSize: "32px"
    fontWeight: 650
    lineHeight: 1.08
    letterSpacing: "0"
  title:
    fontFamily: "system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif"
    fontSize: "20px"
    fontWeight: 650
    lineHeight: 1.2
    letterSpacing: "0"
  body:
    fontFamily: "system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: "0"
  label:
    fontFamily: "system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif"
    fontSize: "13px"
    fontWeight: 600
    lineHeight: 1.25
    letterSpacing: "0"
rounded:
  sm: "10px"
  md: "14px"
  lg: "18px"
  sheet: "24px"
  pill: "999px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
  lg: "24px"
  xl: "32px"
  xxl: "48px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.bg}"
    rounded: "{rounded.md}"
    padding: "14px 18px"
  button-secondary:
    backgroundColor: "{colors.primary-soft}"
    textColor: "{colors.ink}"
    rounded: "{rounded.md}"
    padding: "14px 18px"
  status-chip:
    backgroundColor: "{colors.primary-soft}"
    textColor: "{colors.primary}"
    rounded: "{rounded.pill}"
    padding: "6px 10px"
---

# Design System: Fasting App

## 1. Overview

**Creative North Star: "Autumn Window Light"**

The app should feel like checking in during an ordinary calm moment: soft autumn light at a kitchen table, a small private signal from someone you trust, and no pressure to perform. The interface is product-first and mobile-first. It should be familiar enough to use without thought, but polished enough to make fasting feel cared for.

The system is restrained but warm: clean architecture, softly natural surfaces, an autumn amber primary, and a muted olive/taupe secondary influence from the Material Kolor seed. Beauty comes from proportion, natural color, rounded but disciplined shapes, and smooth state transitions. It explicitly rejects clinical health dashboards, gamified streak energy, loud progress theatrics, and social-feed behavior.

**Key Characteristics:**

- Calm, private, supportive.
- Restrained autumn palette with one primary color used sparingly.
- Rounded mobile surfaces without inflated bubble shapes.
- Smooth motion for state change and feedback only.
- Clear fasting status before decorative detail.

## 2. Colors

The palette is restrained and autumnal: clean white keeps the product crisp, warm amber carries the brand, and muted natural olive/taupe keeps the system intimate rather than clinical.

### Primary

- **Autumn Amber** (`oklch(0.430 0.070 65)`): Primary actions, active Fasting Status, selected plan state, and the strongest progress indicator. Use on less than 10% of a screen.
- **Amber Mist** (`oklch(0.900 0.045 70)`): Soft selected surfaces, quiet status chips, and calm progress backgrounds.

### Secondary

- **Soft Ember** (`oklch(0.560 0.085 35)`): Occasional supportive emphasis, target-reached feedback, and tiny warm moments. Never use it as a competing primary color.
- **Natural Olive Taupe** (`#7B7660` source seed): Material Kolor exploration seed for grounded natural warmth. Use as an influence for neutral and secondary roles, not as a loud fill.

### Neutral

- **Pure App White** (`oklch(1.000 0.000 0)`): Main app background. Keep it truly white; do not tint the entire product beige or cream.
- **Warm Breath Surface** (`oklch(0.965 0.018 75)`): Panels, grouped controls, and quiet secondary sections.
- **Raised Warm White** (`oklch(0.985 0.010 75)`): Sheets and important surfaces that need slight separation.
- **Deep Umber Ink** (`oklch(0.220 0.025 70)`): Primary text and data.
- **Soft Bark Text** (`oklch(0.430 0.020 70)`): Secondary text, metadata, and inactive labels. It must remain readable against white.

### Named Rules

**The Ten Percent Color Rule.** Strong color is scarce. If Autumn Amber or Soft Ember begins to dominate a screen, the product has become too loud.

**The Premium Warmth Rule.** Warm does not mean generic beige wellness branding. Surfaces stay crisp, roles stay clear, and amber is used with restraint.

## 3. Typography

**Display Font:** System sans (`system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif`)
**Body Font:** System sans (`system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif`)
**Label/Mono Font:** System sans unless real data alignment later earns a mono role.

**Character:** Use one high-quality system sans vocabulary so the product feels native on iOS and Android. The hierarchy should feel calm and practical, not editorial or decorative.

### Hierarchy

- **Display** (650, 32px, 1.08): The current fasting number or primary screen-level state. Use sparingly.
- **Headline** (650, 24px, 1.15): Screen headings and major section titles.
- **Title** (650, 20px, 1.2): Card and panel titles.
- **Body** (400, 16px, 1.5): Explanatory copy and standard labels. Keep prose around 65-75ch where possible.
- **Label** (600, 13px, 1.25): Metadata, chips, compact controls, and small status labels. Letter spacing remains 0.

### Named Rules

**The No Shouting Rule.** Fasting status can be large, but labels, buttons, and cards stay product-scale. Do not use hero typography inside compact app panels.

## 4. Elevation

Use tonal layering before shadows. Surfaces separate through white, warm surface, spacing, and borders. Shadows are allowed only for modal sheets, active overlays, and tactile pressed/hover feedback in prototypes.

### Shadow Vocabulary

- **Sheet Lift** (`0 12px 28px rgb(15 23 42 / 0.12)`): Bottom sheets, dialogs, and prototype overlays only.
- **Touchable Lift** (`0 4px 8px rgb(15 23 42 / 0.08)`): Temporary hover/pressed feedback in HTML prototypes. Avoid pairing this with heavy borders.

### Named Rules

**The Flat-At-Rest Rule.** Cards and controls are flat at rest. Depth appears when the user opens, presses, or focuses something.

## 5. Components

### Buttons

- **Shape:** Gently rounded rectangles (14px), not oversized bubbles.
- **Primary:** Autumn Amber fill, Pure App White text, 14px vertical padding, full-width on narrow mobile screens when it is the main action.
- **Hover / Focus:** 180-220ms ease-out transition, visible focus ring, slight tonal darkening or tactile lift. Reduced motion should remove movement while preserving state feedback.
- **Secondary:** Amber Mist fill with Deep Umber Ink text for lower-risk actions like editing start time or choosing another plan.

### Chips

- **Style:** Pill shape for compact Fasting Plan choices and current status labels.
- **State:** Selected chips use Amber Mist with Autumn Amber text or an Autumn Amber fill with white text when emphasis is necessary. Unselected chips stay quiet with a neutral border or surface.

### Cards / Containers

- **Corner Style:** Rounded but disciplined (18px for important panels, 24px only for app sheets or major mobile containers).
- **Background:** Use Raised Warm White or Warm Breath Surface.
- **Shadow Strategy:** No shadow at rest unless the surface is an overlay.
- **Border:** Use subtle full borders only when tonal layering is insufficient. Never use colored side stripes.
- **Internal Padding:** 16px for compact panels, 24px for main status areas.

### Inputs / Fields

- **Style:** Rounded 14px fields with Warm Breath Surface or Raised Warm White fill.
- **Focus:** Autumn Amber focus ring or border. Never rely on color alone; use clear outline thickness.
- **Error / Disabled:** Error states should be calm and specific, not alarming unless data loss is possible.

### Navigation

Navigation should remain minimal for MVP prototypes. Use native mobile tab or top-level segmented patterns only when the workflow earns them. Avoid drawer-style complexity for the first fasting screen.

## 6. Do's and Don'ts

### Do:

- **Do** make Fasting Status readable before anything decorative.
- **Do** use rounded corners, but keep cards at 18px or below unless the element is a sheet.
- **Do** use smooth 180-220ms motion for state changes, plan selection, and timer/progress updates.
- **Do** make sharing/privacy state visible when a Fasting Circle is involved.
- **Do** provide reduced-motion alternatives for every animation.

### Don't:

- **Don't** make the app feel clinical, gamified, overly colorful, competitive, noisy, or like a social feed.
- **Don't** use streak visuals, achievement badges, leaderboards, or loud celebration patterns.
- **Don't** let warm, natural, autumnal color collapse into generic beige wellness branding.
- **Don't** use purple gradients, gradient text, glass cards, decorative bokeh, or generic AI-looking hero surfaces.
- **Don't** hide important fasting timing behind tiny labels, icons without text, or decorative progress rings.
