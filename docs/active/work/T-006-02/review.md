# T-006-02 Review: MDEx Rendering

## Summary

Wired up MDEx for markdown → HTML rendering in the Page resource. Markdown content in `body` is now rendered to HTML in `body_html` on every `:draft` and `:edit` action, with GFM extensions (tables, footnotes, strikethrough) enabled.

## Changes

### Modified Files

1. **`mix.exs`** — Added `{:mdex, "~> 0.2"}` dependency (resolved to 0.11.6). Pulled in transitive deps: `lumis` (syntax highlighting NIF), `rustler_precompiled`.

2. **`lib/haul/content/page.ex`** — Replaced body-copy stub in both `:draft` and `:edit` change functions with `MDEx.to_html!/2` call using GFM extensions:
   ```elixir
   html = MDEx.to_html!(body, extension: [table: true, footnotes: true, strikethrough: true])
   Ash.Changeset.force_change_attribute(changeset, :body_html, html)
   ```

3. **`test/haul/content/page_test.exs`** — Updated 2 existing test assertions to verify HTML output. Added 2 new tests:
   - "renders GFM tables in body_html" — verifies `<table>`, `<td>` tags
   - "renders strikethrough in body_html" — verifies `<del>` tag

### Files Created
- `docs/active/work/T-006-02/` — RDSPI artifacts (research, design, structure, plan, progress, review)

## Test Coverage

- **8 page tests, all passing** (was 6, added 2)
- **128 total tests, 0 failures**
- Covered scenarios:
  - Draft creates page with rendered HTML in body_html ✓
  - Edit re-renders body_html with updated content ✓
  - GFM table extension produces `<table>` output ✓
  - Strikethrough extension produces `<del>` output ✓
  - Publish/unpublish still work ✓
  - Slug uniqueness still enforced ✓
  - Required fields still validated ✓

### Coverage Gaps
- Footnotes extension not explicitly tested (GFM footnote syntax is more complex; tables and strikethrough are sufficient to confirm extensions are active)
- No test for empty body (nil case in change function) — handled by `allow_nil? false` on body attribute, so nil never reaches the change function
- No template rendering test — content page templates don't exist yet (later ticket)

## Acceptance Criteria Status

- [x] `mdex` added to mix.exs deps
- [x] Page `:edit` action renders `body` → `body_html` via `MDEx.to_html!/2`
- [x] Extensions enabled: tables, footnotes, strikethrough (GFM baseline)
- [x] Page `:draft` action also renders body_html on create
- [x] Template helper — not needed yet; `raw/1` is built into Phoenix.HTML and will be used when content page templates are built (T-006-03 or later)
- [x] Test: create a Page with markdown body, verify body_html contains correct HTML
- [x] Test: update body, verify body_html is re-rendered

## Open Concerns

- **NIF dependency**: MDEx uses Rust NIFs via rustler_precompiled. Precompiled binaries are available for common platforms (macOS arm64, Linux x86_64). If CI or Docker builds on an unsupported target, it will need Rust toolchain installed. Current Dockerfile should be fine (Linux x86_64).
- **`mix.lock` changes**: MDEx brings in `lumis` (syntax highlighting) and `rustler_precompiled` as transitive deps. These are lightweight but do add to the dependency tree.
- **No sanitization**: MDEx/comrak output is safe by default (no raw HTML passthrough unless explicitly enabled). The current configuration does not enable `unsafe_` options, so XSS is not a concern.
