# T-006-02 Design: MDEx Rendering

## Decision: Inline Change Function with MDEx.to_html/2

### Approach
Replace the body-copy stub in both `:draft` and `:edit` change functions with `MDEx.to_html/2`. Use GFM extensions (tables, footnotes, strikethrough) as specified.

### Why Inline (Not a Separate Change Module)
- The rendering logic is 4 lines — a case match + one function call
- Both `:draft` and `:edit` need identical logic
- A separate `Haul.Content.Changes.RenderMarkdown` module would be over-engineering for a single function call
- If the logic grows (sanitization, component injection), extract later

### Alternative Considered: Extract to a Shared Module
```elixir
defmodule Haul.Content.Changes.RenderMarkdown do
  use Ash.Resource.Change
  def change(changeset, _opts, _context) do
    # ...
  end
end
```
**Rejected** — adds a file, a module, and indirection for 4 lines of logic. The inline function is clearer and matches existing patterns in the codebase (SiteConfig, Service all use inline changes).

### Alternative Considered: Extract to a Helper Function
A private function on the Page module that both actions call.
**Rejected** — Ash resources don't conventionally define private helper functions. The inline pattern is idiomatic.

### MDEx Configuration
```elixir
MDEx.to_html!(body, extension: [table: true, footnotes: true, strikethrough: true])
```

Using `to_html!` (bang version) instead of `to_html/2` with pattern matching:
- Markdown parsing should never fail on valid string input
- If it does, we want a clear error, not a silent nil
- Matches the fail-fast philosophy of Ash change functions

### Error Handling
- `to_html!` raises on failure — appropriate since markdown input is always a string
- The `case` guard on `nil` body already handles the nil case
- No sanitization needed — MDEx output is safe HTML (comrak's default)

### Test Strategy
- Update existing test assertions: `body_html` should contain rendered HTML tags
- Test markdown with heading → verify `<h1>` in output
- Test markdown with paragraph → verify `<p>` in output
- Add new test: markdown with GFM table → verify `<table>` in output
- Add new test: update body → verify body_html re-rendered with new content

### Dependency Version
- `{:mdex, "~> 0.2"}` — latest stable series
- NIF-based, precompiled binaries available for macOS + Linux
