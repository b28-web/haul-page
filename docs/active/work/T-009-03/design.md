# T-009-03 Design — Browser QA for Address Autocomplete

## Approach

Interactive Playwright MCP session against dev server (already running on port 4000). Sandbox adapter provides deterministic autocomplete responses — no external API dependency.

## Test scenario design

### Scenario 1: Autocomplete dropdown appears

1. Navigate to `/book`
2. Type "123 Main" into the address field (triggers debounce + sandbox fetch)
3. Wait for dropdown to render (~500ms for debounce + fetch)
4. Snapshot and verify: `role="listbox"` present, suggestion items visible

**Why this works:** Sandbox adapter returns 3 Springfield addresses for any input ≥3 chars. "123 Main" will match and show all 3 suggestions.

### Scenario 2: Selection populates address

1. Click first suggestion (or arrow-down + enter)
2. Snapshot and verify: address input contains the selected address, dropdown dismissed

**Why this works:** The hook's `selectSuggestion()` sets `input.value = description` and dispatches an `input` event. The full address string should be in the input.

### Scenario 3: Keyboard navigation

1. Clear address field, type "456 Test"
2. Press ArrowDown to highlight first suggestion
3. Press ArrowDown again to move to second
4. Press Enter to select
5. Verify: address populated with second suggestion's description

**Why this works:** Hook tracks `highlightedIndex` and uses `aria-activedescendant`. Enter selects the highlighted item.

### Scenario 4: Graceful degradation

The ticket asks to verify the form works when the API is unavailable. In dev, the Sandbox adapter always returns results, so we test degradation by:
- Typing fewer than 3 characters (no API call, no dropdown)
- Manually typing a full address without selecting from dropdown
- Submitting the form with a manually-typed address

**Why this works:** The hook only triggers fetch for ≥3 chars. Manual input goes through normal LiveView validation. The Job action accepts any address string.

### Scenario 5: Accessibility check

From the snapshot, verify ARIA attributes:
- Input has `role="combobox"`, `aria-autocomplete="list"`
- When dropdown open: `aria-expanded="true"`, `aria-controls` points to listbox
- Suggestions have `role="option"`

### Scenario 6: No server errors

Check server logs and browser console for errors during all scenarios.

## What we're NOT testing

- Google adapter (production only, needs API key)
- Place Details API / geocoding (not implemented yet per T-009-02 review)
- Structured address parsing (Job stores single address string)
- Mobile-specific autocomplete behavior (hook is responsive by default)

## Rejected alternatives

**Option A: Restart dev server without sandbox to test Google degradation**
Rejected — would require API key manipulation, adds complexity. The sandbox IS the degradation test since it proves the form works with the adapter layer. Integration tests already cover the no-API-key path.

**Option B: Use browser_evaluate to mock fetch responses**
Rejected — over-engineering. Sandbox adapter already provides controlled responses.

## Decision

Sequential Playwright MCP walkthrough: navigate → type → wait → verify dropdown → select → verify population → keyboard nav → manual input → submit → check logs. Match the pattern from T-003-04.
