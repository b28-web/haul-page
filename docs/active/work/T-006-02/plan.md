# T-006-02 Plan: MDEx Rendering

## Step 1: Add MDEx dependency
- Add `{:mdex, "~> 0.2"}` to `mix.exs` deps
- Run `mix deps.get` to fetch and compile
- Verify: `mix deps | grep mdex` shows the package

## Step 2: Update Page resource change functions
- In `lib/haul/content/page.ex`, replace both `:draft` and `:edit` change functions
- Old: `Ash.Changeset.force_change_attribute(changeset, :body_html, body)`
- New: `Ash.Changeset.force_change_attribute(changeset, :body_html, MDEx.to_html!(body, extension: [table: true, footnotes: true, strikethrough: true]))`

## Step 3: Update existing tests
- In `test/haul/content/page_test.exs`:
  - "creates a draft page with body_html populated": change assertion from exact string match to `assert page.body_html =~ "<h1>"` and `assert page.body_html =~ "<p>"`
  - "updates body and regenerates body_html": change assertion to verify HTML output

## Step 4: Add GFM extension tests
- Add test "renders GFM tables in body_html": create page with markdown table, verify `<table>` in body_html
- Add test "renders strikethrough in body_html": create page with `~~text~~`, verify `<del>` in body_html

## Step 5: Run full test suite
- `mix test` — all tests pass
- `mix test test/haul/content/page_test.exs` — page tests specifically

## Verification Criteria
- [ ] `mdex` in mix.lock
- [ ] Page `:draft` renders markdown to HTML in body_html
- [ ] Page `:edit` re-renders markdown to HTML in body_html
- [ ] GFM tables render to `<table>` elements
- [ ] Strikethrough renders to `<del>` elements
- [ ] All existing tests still pass
