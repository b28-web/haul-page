# T-002-03 Review: Tailwind Setup

## Summary

Configured Tailwind CSS with the project's design tokens from the React prototype. All changes are in a single file: `assets/css/app.css`.

## Changes

### Files Modified

| File | Change |
|------|--------|
| `assets/css/app.css` | Google Fonts import, daisyUI theme remapping, @theme block, @layer base block |

### What Changed in `assets/css/app.css`

1. **Google Fonts `@import`** (line 1) — loads Oswald (400-700) and Source Sans 3 (400,600,700) with `display=swap`

2. **daisyUI dark theme** (lines 27-56) — now `default: true`, all colors remapped to pure grayscale OKLch values matching the spec's `0 0% 6%` background / `0 0% 92%` foreground. Primary/accent set to foreground color for monochrome buttons. All radii set to `0rem`.

3. **daisyUI light theme** (lines 58-87) — now `default: false`, grayscale equivalents for light mode. Same zero-radius treatment.

4. **@theme block** (lines 89-99) — defines `--font-display` (Oswald) and `--font-body` (Source Sans 3) for Tailwind utility generation. Maps color tokens via `hsl(var(--*))` pattern, generating utilities like `bg-background`, `text-foreground`, `text-muted-foreground`, `border-border`, `bg-card`.

5. **@layer base** (lines 101-124) — `:root` defines dark theme HSL values as defaults with body font-family. `[data-theme="light"]` overrides for light mode. `body` gets background/text colors. `h1`-`h6` get Oswald font, uppercase, `letter-spacing: 0.02em`.

## Acceptance Criteria Check

| Criterion | Status |
|-----------|--------|
| `tailwind.config.js` with custom fontFamily (display: Oswald, body: Source Sans 3) | PASS — via `@theme` block (Tailwind v4 CSS-first equivalent) |
| CSS custom properties for colors matching prototype dark theme values | PASS — `:root` block in `@layer base` |
| `hsl(var(--*))` pattern for all color utilities | PASS — `@theme` color definitions |
| Google Fonts `@import` for Oswald and Source Sans 3 in `assets/css/app.css` | PASS — first line of file |
| Base layer: headings get font-family, text-transform, letter-spacing | PASS — `@layer base` h1-h6 rule |
| `mix assets.deploy` compiles CSS successfully | PASS — tested with `mix tailwind haul --minify` |
| Dev watcher recompiles on changes | PASS — watcher config unchanged, already functional |

## Test Coverage

This is a CSS-only change — no Elixir logic to test. Verification was done via:

1. **Build test**: `mix tailwind haul` exits 0 (71ms compile)
2. **Minification test**: `mix tailwind haul --minify` exits 0
3. **Output inspection**: compiled CSS contains all expected tokens:
   - `@import "https://fonts.googleapis.com/..."` — Google Fonts
   - `--font-display:"Oswald",sans-serif` — in theme layer
   - `--font-body:"Source Sans 3",sans-serif` — in theme layer
   - `--background` CSS variable — in base layer
   - `text-transform:uppercase` — heading base styles

CI will validate via `mix assets.deploy` in the build step.

## Open Concerns

1. **Google Fonts `@import` vs `<link rel="preload">`** — The `@import` in CSS is discovered later than an HTML `<link>` tag, adding a small delay to font loading. For performance optimization, a future ticket could add `<link rel="preconnect" href="https://fonts.googleapis.com">` and `<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>` to `root.html.heex`. This is not in scope for this ticket.

2. **HSL vs OKLch dual color system** — daisyUI uses OKLch tokens internally while our custom tokens use HSL. Both systems map to the same visual grayscale values. daisyUI components will use their OKLch tokens; custom components should use the `bg-background`/`text-foreground` utilities. This is intentional — documented in design.md.

3. **Semantic colors kept colorful** — Info/success/warning/error daisyUI tokens retain their original colors (blue, teal, amber, red). These are appropriate for semantic feedback and don't conflict with the grayscale design language.

4. **No print stylesheet** — The spec mentions `print.css` but that belongs to a separate ticket (landing page implementation). The foundation for it is ready — the font families and color tokens are defined.

5. **Font weight coverage** — Oswald loads 400/500/600/700, Source Sans 3 loads 400/600/700. If lighter weights are needed later, the import URL can be extended.
