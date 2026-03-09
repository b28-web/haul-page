---
id: T-002-03
story: S-002
title: tailwind-setup
type: task
status: open
priority: high
phase: done
depends_on: [T-001-01]
---

## Context

Configure Tailwind CSS with the project's design tokens from the React prototype. Phoenix ships with Tailwind support via the `tailwind` Mix task.

## Design tokens (from prototype)

**Fonts:**
- Display: `Oswald` (Google Fonts) — headings, uppercase, `letter-spacing: 0.02em`
- Body: `Source Sans 3` (Google Fonts) — body text
- Loaded via Google Fonts `@import` in CSS

**Colors (dark theme — default):**
- `--background: 0 0% 6%` (near-black)
- `--foreground: 0 0% 92%` (near-white)
- `--muted-foreground: 0 0% 55%` (mid-gray for secondary text)
- `--border: 0 0% 22%`
- All colors are pure grayscale (hue 0, saturation 0%)
- `--radius: 0rem` — no border radius anywhere (sharp edges)

**Light theme defined but not used as default.** Dark is the primary theme.

## Acceptance Criteria

- `tailwind.config.js` with custom `fontFamily` (display: Oswald, body: Source Sans 3)
- CSS custom properties for colors matching prototype's dark theme values
- `hsl(var(--*))` pattern for all color utilities (background, foreground, muted, etc.)
- Google Fonts `@import` for Oswald and Source Sans 3 in `assets/css/app.css`
- Base layer: headings get `font-family: var(--font-display)`, `text-transform: uppercase`, `letter-spacing: 0.02em`
- `mix assets.deploy` compiles CSS successfully
- Dev watcher recompiles on changes
