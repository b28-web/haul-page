# T-002-03 Structure: Tailwind Setup

## Files Modified

### 1. `assets/css/app.css` (primary target)

**Section ordering** (top to bottom):

```
1. Google Fonts @import
2. Tailwind import + source directives (existing)
3. @plugin directives (existing, heroicons + daisyUI)
4. daisyUI theme blocks (modified — grayscale + dark default)
5. @theme block (NEW — font families + color token mappings)
6. @layer base (NEW — CSS variable definitions + heading styles)
7. Custom variants (existing)
8. LiveView wrapper styles (existing)
```

**Changes by section:**

**Section 1 — Google Fonts import (NEW)**
- Add `@import url('https://fonts.googleapis.com/css2?family=Oswald:wght@400;500;600;700&family=Source+Sans+3:wght@400;600;700&display=swap');`
- Must be FIRST line before any other imports

**Section 4 — daisyUI theme blocks (MODIFIED)**
- Dark theme: change `default: false` → `default: true`, remap base colors to grayscale OKLch, set all radius to `0rem`
- Light theme: change `default: true` → `default: false`, remap base colors to light grayscale OKLch, set all radius to `0rem`
- Both themes: set primary/secondary/accent/neutral to grayscale values

**Section 5 — @theme block (NEW)**
```
@theme {
  --font-display: 'Oswald', sans-serif;
  --font-body: 'Source Sans 3', sans-serif;
  --color-background: hsl(var(--background));
  --color-foreground: hsl(var(--foreground));
  --color-muted-foreground: hsl(var(--muted-foreground));
  --color-border: hsl(var(--border));
  --color-card: hsl(var(--card));
}
```
This generates Tailwind utilities: `font-display`, `font-body`, `bg-background`, `text-foreground`, `border-border`, etc.

**Section 6 — @layer base (NEW)**
```
@layer base {
  :root {
    --background: 0 0% 6%;
    --foreground: 0 0% 92%;
    --muted-foreground: 0 0% 55%;
    --border: 0 0% 22%;
    --card: 0 0% 10%;
    --radius: 0rem;
    font-family: var(--font-body);
  }

  [data-theme="light"] {
    --background: 0 0% 100%;
    --foreground: 0 0% 8%;
    --muted-foreground: 0 0% 40%;
    --border: 0 0% 75%;
    --card: 0 0% 100%;
  }

  body {
    background-color: hsl(var(--background));
    color: hsl(var(--foreground));
  }

  h1, h2, h3, h4, h5, h6 {
    font-family: var(--font-display);
    text-transform: uppercase;
    letter-spacing: 0.02em;
  }
}
```

## Files NOT Modified

- `config/config.exs` — tailwind build config already correct
- `config/dev.exs` — watcher already configured
- `mix.exs` — no dep changes needed
- `assets/vendor/*` — vendored plugins untouched
- `lib/haul_web/components/layouts/root.html.heex` — font loading via CSS import, not HTML link tags
- `lib/haul_web.ex` — `fonts/` already in static_paths

## Module Boundaries

No new modules. All changes are CSS-only. The design token system is pure CSS custom properties consumed by Tailwind's utility generator.

## Ordering Constraints

1. Google Fonts `@import` must be first (CSS spec requirement — `@import` must precede other rules except `@charset`)
2. `@theme` block must come after plugin directives (Tailwind v4 processes plugins before theme)
3. `@layer base` must come after `@theme` (base styles reference theme variables)

## Verification Points

After changes, these should all work:
- `mix tailwind haul` compiles without errors
- `mix assets.deploy` completes (minified CSS output)
- Dev server (`mix phx.server`) recompiles CSS on changes to `app.css`
- Generated CSS contains:
  - Google Fonts `@import`
  - `--background`, `--foreground` etc. custom properties
  - `.font-display` and `.font-body` utility classes
  - `h1`-`h6` base styles with Oswald font
  - Dark grayscale colors as default
