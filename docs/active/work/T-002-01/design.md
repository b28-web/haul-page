# Design — T-002-01 Landing Page Markup

## Decision 1: Layout strategy

### Options

**A) Use `Layouts.app` wrapper** — Render inside existing navbar+main layout.
- Pro: Consistent with other pages
- Con: Landing page has no navbar — it IS the full page. Navbar adds irrelevant chrome.

**B) Bypass `Layouts.app`, render directly in root layout** — Controller sets `layout: false` for the app layout, content goes straight into `{@inner_content}` of root.
- Pro: Full control over page structure. No navbar.
- Con: Need to handle flash manually if wanted.

**C) Create a `Layouts.landing` layout** — Dedicated layout component for public pages.
- Pro: Reusable for future public pages. Clean separation.
- Con: Only one landing page for now — premature abstraction.

**Decision: B** — Use `put_layout(conn, false)` in controller to skip the app layout. The landing page renders directly inside root. Flash messages aren't needed on the landing page. If we add more public pages later, we can extract a layout then.

## Decision 2: Operator config source

### Options

**A) Hardcode values in template** — Direct strings in HEEx.
- Pro: Simplest. Ship fast.
- Con: Violates acceptance criteria ("wired from runtime config"). Not operator-configurable.

**B) Application env with runtime.exs overrides** — `config :haul, :operator` map in config, overridden by env vars in runtime.exs.
- Pro: Works now, no DB needed. Env vars match Fly.io deploy pattern. Clean path to Content domain later.
- Con: Requires redeploy to change values.

**C) Read from Ash Content.SiteConfig** — Query the DB singleton.
- Pro: Matches long-term design. Operator-editable.
- Con: Content domain doesn't exist yet. Premature dependency.

**Decision: B** — Application config with env var overrides. Define defaults in `config.exs`, override in `runtime.exs` from env vars. Controller reads `Application.get_env(:haul, :operator)` and passes to template as assigns. When Content domain lands, swap the source in the controller — template stays the same.

## Decision 3: Services data source

### Options

**A) Hardcoded list in controller** — Return a static list of maps.
- Pro: Zero infrastructure.
- Con: Not configurable.

**B) Application config** — Define services list in config, pass as assign.
- Pro: Consistent with operator config approach. Configurable per environment.
- Con: More config to maintain.

**C) Separate module** — `Haul.Defaults` module with service definitions.
- Pro: Clean code organization.
- Con: Another module for six items.

**Decision: B** — Services list in operator config. Same `Application.get_env(:haul, :operator)` map includes a `:services` key. Default list matches the six services from the spec. Operators can eventually override via Content domain.

## Decision 4: Icon strategy for missing Heroicons

TreePine and Hammer have no direct Heroicons equivalent.

### Options

**A) Inline SVG in template** — Copy Lucide SVGs directly into HEEx.
- Pro: Exact match to prototype.
- Con: Verbose templates.

**B) Custom icon component** — Add SVG icons to a component module.
- Pro: Reusable. Clean templates.
- Con: Over-engineering for two icons.

**C) Use closest Heroicons** — TreePine→`hero-leaf`, Hammer→`hero-wrench-screwdriver`.
- Pro: Zero custom code. Consistent icon set.
- Con: Not exact match to prototype.

**Decision: C** — Use closest Heroicons. The icon choice is cosmetic and can be swapped later when Content domain allows configurable icon names. Mapping: TreePine→`hero-sparkles` (cleanup/nature feel), Hammer→`hero-wrench-screwdriver`.

## Decision 5: Print styles approach

### Options

**A) Inline `@media print` in app.css** — Add print rules to the main stylesheet.
- Pro: Single file. Always loaded.
- Con: Bloats main CSS for all pages.

**B) Separate print stylesheet** — `<link media="print" href="print.css">`.
- Pro: Only loaded when printing. Clean separation.
- Con: Requires separate Tailwind build or manual CSS file.

**C) Print utilities in app.css via `@media print`** — Add a focused block at the end of app.css.
- Pro: Part of Tailwind build. Can use Tailwind's print: variant. Minimal addition.
- Con: Loaded on all pages.

**Decision: C** — Add `@media print` block to app.css. The print styles are ~30 lines. Tailwind already provides `print:` variant for show/hide. The tear-off strip gets `hidden print:flex`. Screen-only elements get `print:hidden`.

## Decision 6: Template organization

### Options

**A) Single `home.html.heex`** — One file with all four sections.
- Pro: Simple. Easy to find everything.
- Con: Could get long (200+ lines).

**B) Multiple template files** — Split into partials rendered from PageHTML.
- Pro: Organized by section.
- Con: Phoenix convention is function components, not partials. Over-engineering.

**C) Function components in PageHTML** — Define `hero/1`, `services_grid/1`, `why_us/1`, `footer_cta/1` in PageHTML module, call from `home.html.heex`.
- Pro: Organized. Follows Phoenix conventions. Each section testable independently.
- Con: Slightly more code.

**Decision: A** — Single template file. The landing page is ~200 lines of markup. Splitting into components adds indirection without benefit at this scale. If sections grow or get reused, extract then.
