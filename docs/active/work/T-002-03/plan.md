# T-002-03 Plan: Tailwind Setup

## Step 1: Add Google Fonts import

**Action**: Insert `@import url(...)` as the very first line of `assets/css/app.css`.

**Verification**: File parses correctly (no syntax errors). The import URL loads fonts for Oswald (400-700) and Source Sans 3 (400,600,700) with `display=swap`.

## Step 2: Update daisyUI dark theme to grayscale default

**Action**: In `assets/css/app.css`, modify the dark daisyUI theme block:
- `default: false` → `default: true`
- Remap `--color-base-100` to `oklch(14.9% 0 0)` (≈ hsl 0 0% 6%)
- Remap `--color-base-200` to `oklch(20.5% 0 0)` (≈ hsl 0 0% 10%)
- Remap `--color-base-300` to `oklch(32.4% 0 0)` (≈ hsl 0 0% 22%)
- Remap `--color-base-content` to `oklch(93.9% 0 0)` (≈ hsl 0 0% 92%)
- Set primary/secondary to white-on-dark monochrome
- Set all `--radius-*` to `0rem`

## Step 3: Update daisyUI light theme

**Action**: Modify the light daisyUI theme block:
- `default: true` → `default: false`
- Remap base colors to light grayscale equivalents
- Set all `--radius-*` to `0rem`

## Step 4: Add @theme block for Tailwind utilities

**Action**: Add `@theme` block after plugin directives with:
- `--font-display: 'Oswald', sans-serif`
- `--font-body: 'Source Sans 3', sans-serif`
- Color mappings using `hsl(var(--*))` pattern

**Verification**: Tailwind should generate `font-display`, `font-body`, `bg-background`, `text-foreground`, `text-muted-foreground`, `border-border`, `bg-card` utilities.

## Step 5: Add @layer base block

**Action**: Add `@layer base` with:
- `:root` — dark theme HSL values (default), body font-family
- `[data-theme="light"]` — light theme HSL values
- `body` — background and text color from tokens
- `h1`-`h6` — Oswald font, uppercase, letter-spacing

## Step 6: Build verification

**Action**: Run `mix tailwind haul` and `mix assets.deploy` to confirm:
- No compilation errors
- CSS output contains all expected tokens and utilities
- File size is reasonable

## Step 7: Dev watcher verification

**Action**: Start dev server, modify a CSS value, confirm recompilation triggers.

## Testing Strategy

This ticket is CSS-only — no Elixir logic to unit test. Verification is:

1. **Build test**: `mix tailwind haul` exits 0
2. **Deploy test**: `mix assets.deploy` exits 0 (includes minification)
3. **Output inspection**: grep compiled CSS for key tokens (`--background`, `--foreground`, `font-family.*Oswald`)
4. **Visual check**: load page in browser, confirm dark background, correct fonts

No automated test files to create. The CI pipeline already runs `mix assets.deploy` as part of the build, which will catch CSS compilation errors.

## Commit Plan

Single atomic commit: "Configure Tailwind with design tokens, fonts, and dark theme"

All changes are in `assets/css/app.css` — one file, one commit.
