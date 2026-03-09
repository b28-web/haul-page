# T-002-02 Plan: Print Stylesheet

## Step 1: Add missing print CSS rules

**File:** `assets/css/app.css`

Add three rules to the existing `@media print` block (before the closing `}`):

1. `[class*="max-w-"] { max-width: none !important; }` — removes max-width constraints
2. `section { break-inside: avoid; }` — prevents page breaks inside sections
3. `svg { color: black !important; }` — ensures SVG icons print visibly

**Verify:** `mix assets.deploy` compiles successfully.

## Step 2: Add `@url` assign to PageController

**File:** `lib/haul_web/controllers/page_controller.ex`

Add `|> assign(:url, HaulWeb.Endpoint.url())` to the assign chain in `home/2`.

**Verify:** Controller compiles.

## Step 3: Add print-only URL display in template

**File:** `lib/haul_web/controllers/page_html/home.html.heex`

Insert a `hidden print:block` paragraph between the `print:hidden` business name line (103-105) and the tear-off strip comment (107), showing `{@url} · {@phone}`.

**Verify:** Template compiles. URL appears in print preview, hidden on screen.

## Step 4: Verify with `mix compile`

Run `mix compile --warnings-as-errors` to confirm no warnings.

## Step 5: Browser verification

Use Playwright to:
1. Navigate to `http://localhost:4000`
2. Verify the URL paragraph is hidden on screen
3. Take a screenshot for visual confirmation

Note: Full print preview testing requires manual browser verification (Playwright can't capture print preview). The AC says "Tested via browser print preview" — this will be noted as requiring manual QA.

## Testing Strategy

- **No unit tests needed** — this is pure CSS + template markup
- **Compilation check** — `mix compile` catches template/assign mismatches
- **Visual verification** — browser print preview (manual QA, documented in review)
- **Existing tests** — run `mix test` to confirm no regressions

## Commit Plan

Single atomic commit with all three file changes — they're tightly coupled and small.
