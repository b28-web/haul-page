# T-002-03 Design: Tailwind Setup

## Decision 1: Font Loading Strategy

### Options
A. **Google Fonts `@import` in CSS** — single `@import url(...)` at top of `app.css`
B. **`<link>` tags in `root.html.heex`** — preload + stylesheet links in HTML `<head>`
C. **Self-hosted woff2 in `assets/static/fonts/`** — no external dependency

### Decision: Option A — `@import` in CSS

Rationale:
- The ticket AC explicitly says "Google Fonts `@import` for Oswald and Source Sans 3 in `assets/css/app.css`"
- Simplest approach, single file change
- Tailwind v4 processes `@import url()` directives natively
- The mockup-reference.md provides the exact import URL
- Self-hosting (C) adds file management overhead and isn't requested
- HTML link tags (B) work but split font config across two files

Performance note: `@import` in CSS is slightly slower than `<link rel="preload">` in HTML because it's discovered later. For a production optimization pass, we could add preload hints. But the ticket doesn't ask for that — it asks for `@import` in CSS.

## Decision 2: Color Token Architecture

### Options
A. **Replace daisyUI theme colors** — convert daisyUI OKLch tokens to grayscale equivalents
B. **Parallel HSL custom properties** — add `--background`, `--foreground` etc. alongside daisyUI tokens
C. **Remove daisyUI themes, use only HSL tokens** — strip daisyUI theme plugin entirely

### Decision: Option B — Parallel HSL custom properties + remap daisyUI base colors

Rationale:
- The ticket requires `hsl(var(--*))` pattern for color utilities — this is the shadcn/ui convention
- daisyUI components (buttons, cards, etc.) need daisyUI tokens to function
- The two systems serve different purposes: daisyUI tokens for component library, HSL tokens for custom layout/components
- We remap daisyUI's `base-100/200/300` and `base-content` to match our grayscale values so daisyUI components visually match the design
- Our custom `--background`, `--foreground` etc. properties are defined in a `@theme` block for Tailwind utility generation

Additionally, we must flip the default: dark should be `default: true`, light should be `default: false`. The current setup has this backwards relative to the spec.

## Decision 3: Where to Define Custom Tokens

### Options
A. **`@theme` block in `app.css`** — Tailwind v4's native mechanism for design tokens
B. **`@layer base` with `:root` styles** — plain CSS custom properties
C. **Both** — `@theme` for Tailwind utilities, `@layer base` for CSS variables

### Decision: Option C — Both

Rationale:
- `@theme` is needed so Tailwind generates utility classes like `bg-background`, `text-foreground`
- `@layer base` with `:root` / `[data-theme=dark]` is needed for the actual CSS variable values that change between themes
- Font families go in `@theme` so `font-display` and `font-body` utilities are generated
- The `@theme` block references the CSS variables: `--color-background: hsl(var(--background))`

## Decision 4: daisyUI Theme Remapping

### Approach
Convert the spec's HSL grayscale values to OKLch for daisyUI tokens:

| Spec HSL | OKLch equivalent |
|----------|-----------------|
| `0 0% 6%` (bg dark) | `oklch(14.9% 0 0)` |
| `0 0% 92%` (fg dark) | `oklch(93.9% 0 0)` |
| `0 0% 10%` (card dark) | `oklch(20.5% 0 0)` |
| `0 0% 22%` (border dark) | `oklch(32.4% 0 0)` |
| `0 0% 55%` (muted dark) | `oklch(61.3% 0 0)` |

Saturation 0 in both HSL and OKLch means chroma 0, hue 0 — pure gray.

Set all `--radius-*` to `0rem` to match `--radius: 0rem` spec.

Keep daisyUI's semantic colors (primary, secondary, accent, info, success, warning, error) as neutral grays for now — the design is monochrome. Primary actions use foreground-on-background contrast.

## Decision 5: Base Layer Heading Styles

### Approach
Add `@layer base` block with:
```css
h1, h2, h3, h4, h5, h6 {
  font-family: var(--font-display);
  text-transform: uppercase;
  letter-spacing: 0.02em;
}
```

This matches the ticket AC: "headings get `font-family: var(--font-display)`, `text-transform: uppercase`, `letter-spacing: 0.02em`"

## Decision 6: Dark Mode Variant

### Current
`@custom-variant dark` targets `[data-theme=dark]` — this is correct for the data-theme switching system.

### Change needed
None for the variant itself. But we need dark to be the visual default. Two mechanisms ensure this:
1. daisyUI dark theme gets `default: true` (renders dark colors when no data-theme is set)
2. The `@layer base` `:root` block sets dark HSL values as defaults

## Rejected Alternatives

- **Removing daisyUI entirely**: The scaffold included daisyUI intentionally. Components like buttons, forms, and modals will use daisyUI classes. Removing it creates more work downstream.
- **Using Tailwind v3 config file**: The project is on Tailwind v4 with CSS-first config. Adding a `tailwind.config.js` would be a regression.
- **Operator-configurable colors via CSS variables at runtime**: The spec mentions `OPERATOR_COLOR` env var, but that's for a future ticket. This ticket establishes the default dark grayscale theme.
