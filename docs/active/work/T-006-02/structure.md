# T-006-02 Structure: MDEx Rendering

## Files Modified

### 1. `mix.exs`
- Add `{:mdex, "~> 0.2"}` to deps list, in a new "# Markdown rendering" section after QR code generation

### 2. `lib/haul/content/page.ex`
- `:draft` action change function: replace `body` passthrough with `MDEx.to_html!` call
- `:edit` action change function: replace `body` passthrough with `MDEx.to_html!` call
- Both use identical rendering: `MDEx.to_html!(body, extension: [table: true, footnotes: true, strikethrough: true])`

### 3. `test/haul/content/page_test.exs`
- Update "creates a draft page with body_html populated" assertion: expect HTML output containing `<h1>` and `<p>` tags
- Update "updates body and regenerates body_html" assertion: expect HTML output
- Add new test "renders GFM tables in body_html" to verify table extension
- Add new test "renders strikethrough in body_html" to verify strikethrough extension

## Files NOT Modified
- No new modules created
- No template changes (content page templates are a later ticket)
- No migration needed (body_html column already exists)
- No Content domain changes

## Module Boundaries
- MDEx is called only from Page resource change functions
- No public API added — rendering is internal to the write path
- Template consumption of `body_html` via `raw/1` is unchanged (already planned in spec)

## Ordering
1. Add dep to mix.exs → `mix deps.get`
2. Update Page resource change functions
3. Update tests
4. Run `mix test` to verify
