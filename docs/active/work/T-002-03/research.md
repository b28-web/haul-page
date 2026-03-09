# T-002-03 Research: Tailwind Setup

## Current Asset Pipeline

### Tailwind Configuration
- **Version**: Tailwind CSS v4.1.12 (CSS-first config, no `tailwind.config.js`)
- **Entry**: `assets/css/app.css` using `@import "tailwindcss" source(none)`
- **Sources**: `@source` directives scan `../css`, `../js`, `../../lib/haul_web`
- **Build**: `config/config.exs` lines 44-53 — `tailwind` Mix task with `--input`/`--output` args
- **Dev watcher**: `config/dev.exs` line 29 — `{Tailwind, :install_and_run, [:haul, ~w(--watch)]}`
- **Deploy**: `mix.exs` alias `assets.deploy` runs `tailwind haul --minify`, `esbuild haul --minify`, `phx.digest`

### esbuild Configuration
- **Version**: 0.25.4
- Bundles `assets/js/app.js` with `--external:/fonts/*` and `--external:/images/*`
- NODE_PATH includes deps and build path

### Plugins Loaded
1. **heroicons** (`assets/vendor/heroicons.js`) — provides `hero-*` icon classes from SVGs in `deps/heroicons/optimized`
2. **daisyUI** (`assets/vendor/daisyui.js`) — component library, loaded with `themes: false`
3. **daisyUI-theme** (`assets/vendor/daisyui-theme.js`) — theme plugin, invoked twice (dark + light)

### Current Theme Setup
Two daisyUI theme blocks in `app.css` (lines 24-92):
- **"dark"** theme: `default: false`, `prefersdark: true` — applied via `prefers-color-scheme: dark`
- **"light"** theme: `default: true`, `prefersdark: false` — applied as default via `:where(:root)`

Colors use **OKLch** (daisyUI v4 default), with purple/blue Phoenix-brand tones. These do NOT match the spec's pure grayscale HSL tokens.

### Theme Switching
`root.html.heex` includes inline JS (lines 14-30) that:
- Reads `localStorage("phx:theme")` on load
- Sets `data-theme` attribute on `<html>`
- The `@custom-variant dark` in CSS targets `[data-theme=dark]`
- daisyUI-theme plugin also generates `[data-theme="dark"]` selectors

### Current Custom Variant
Line 100: `@custom-variant dark (&:where([data-theme=dark], [data-theme=dark] *));`
This enables `dark:*` utilities but only via data-theme attribute, not `prefers-color-scheme`.

### Static Paths
`lib/haul_web.ex` line 20: `~w(assets fonts images favicon.ico robots.txt)` — `fonts/` is already in the static paths list.

### What's Missing (per ticket acceptance criteria)
1. **No Google Fonts import** — neither `@import url(...)` nor `<link>` tag
2. **No custom font families** — no `--font-display` or `--font-body` theme variables
3. **No HSL CSS custom properties** — colors are daisyUI OKLch tokens, not `--background`, `--foreground`, etc.
4. **No base layer heading styles** — no `@layer base` block for h1-h6
5. **No `hsl(var(--*))` pattern** — the color system doesn't use this approach
6. **Radius is 0.25rem/0.5rem** — spec requires `0rem` (no rounded corners)
7. **Dark theme is not the explicit default** — light is `default: true`, dark only activates via `prefers-color-scheme: dark`

### Design Token Spec (from mockup-reference.md)

| Token | Dark (default) | Light |
|-------|---------------|-------|
| background | `0 0% 6%` | `0 0% 100%` |
| foreground | `0 0% 92%` | `0 0% 8%` |
| muted-foreground | `0 0% 55%` | `0 0% 40%` |
| border | `0 0% 22%` | `0 0% 75%` |
| card | `0 0% 10%` | `0 0% 100%` |

- All pure grayscale (hue 0, saturation 0%)
- `--radius: 0rem`

### Typography Spec
- **Display**: Oswald, weights 400/500/600/700, `letter-spacing: 0.02em`, uppercase
- **Body**: Source Sans 3, weights 400/600/700
- Google Fonts URL: `https://fonts.googleapis.com/css2?family=Oswald:wght@400;500;600;700&family=Source+Sans+3:wght@400;600;700&display=swap`

### Tailwind v4 Mechanisms
- `@theme` block defines design tokens as CSS custom properties (replaces `theme.extend` in v3)
- `@layer base` for default element styles
- `@import url(...)` at top of file for external resources
- Plugins via `@plugin` directive

### Interaction with daisyUI
daisyUI uses its own color token system (`--color-base-100`, `--color-primary`, etc.) in OKLch. The ticket's HSL custom properties (`--background`, `--foreground`) are a separate, parallel system inspired by shadcn/ui. Both can coexist — daisyUI components use daisyUI tokens, custom components use the HSL tokens.

### Files That Will Change
- `assets/css/app.css` — primary target (fonts, tokens, base styles, theme config)
- `lib/haul_web/components/layouts/root.html.heex` — potentially for font preload links

### Files That Should NOT Change
- `config/config.exs` — tailwind/esbuild config already correct
- `config/dev.exs` — watcher already configured
- `mix.exs` — deps and aliases already correct
- `assets/vendor/*` — vendored plugins stay as-is
