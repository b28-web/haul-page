# T-006-02 Research: MDEx Rendering

## Current State

### Page Resource (`lib/haul/content/page.ex`)
- Attributes: `slug`, `title`, `body` (markdown source), `body_html` (cached HTML), `meta_description`, `published`, `published_at`
- Actions: `:draft` (create), `:edit` (update), `:publish`, `:unpublish`
- Both `:draft` and `:edit` have inline change functions that **copy body to body_html verbatim** — no markdown rendering
- `:edit` has `require_atomic? false` (needed for inline change functions)
- `:draft` does NOT have `require_atomic? false` (create actions don't need it)

### Change Function Pattern
```elixir
change fn changeset, _context ->
  case Ash.Changeset.get_attribute(changeset, :body) do
    nil -> changeset
    body -> Ash.Changeset.force_change_attribute(changeset, :body_html, body)
  end
end
```
This is the exact pattern to modify — replace the `body` passthrough with `MDEx.to_html/2` call.

### Existing Tests (`test/haul/content/page_test.exs`)
- "creates a draft page with body_html populated" — asserts `body_html == "# About\n\nWe haul junk."` (raw markdown, not HTML)
- "updates body and regenerates body_html" — asserts `body_html == new_body` (raw markdown)
- These tests will need updating to assert HTML output instead

### Content System Spec (`docs/knowledge/content-system.md`)
- Specifies write-time rendering: `MDEx.to_html/2` in change function
- Extensions: `table: true, footnotes: true, strikethrough: true`
- Template rendering: `raw(@page.body_html)` or `Phoenix.HTML.raw/1`
- Exact API call from spec:
  ```elixir
  {:ok, html} = MDEx.to_html(body, extension: [table: true, footnotes: true, strikethrough: true])
  ```

### Dependencies (`mix.exs`)
- MDEx is NOT currently in deps
- MDEx hex package: `mdex` — NIF-based CommonMark/GFM renderer (wraps comrak in Rust)
- Current Elixir: ~> 1.19, OTP 28

### Template Usage
- Spec shows `<%= raw(@page.body_html) %>` in templates
- No content page templates exist yet (that's a later ticket)
- No helper module needed yet — `raw/1` is built into Phoenix.HTML

## Constraints
- MDEx is a NIF package (Rust) — needs compilation, may affect CI/Docker build time
- The `to_html/2` function returns `{:ok, html}` tuple — must pattern match
- Extensions map directly to comrak options

## Files to Modify
1. `mix.exs` — add `{:mdex, "~> 0.2"}` dep
2. `lib/haul/content/page.ex` — update change functions in `:draft` and `:edit`
3. `test/haul/content/page_test.exs` — update assertions to expect rendered HTML

## Files to Potentially Create
- None required for this ticket. Template helpers are for later tickets.
