# T-009-03 Plan — Browser QA for Address Autocomplete

## Prerequisites

- Dev server running: `http://localhost:4000` (confirmed)
- Playwright MCP available (configured in `.mcp.json`)

## Step 1: Navigate and Verify Page Load

1. `browser_navigate` to `http://localhost:4000/book`
2. `browser_snapshot` — capture initial state
3. **Verify:** Page loads, address field present with:
   - `id="address-autocomplete"`
   - `phx-hook="AddressAutocomplete"`
   - `autocomplete="off"`
   - Wrapped in relative container
4. **Pass criteria:** Address field renders with hook attached

## Step 2: Trigger Autocomplete Dropdown

1. `browser_click` on the address input field
2. `browser_type` "123 Main" into the address field
3. Wait ~500ms for debounce (300ms) + fetch
4. `browser_snapshot` — capture dropdown state
5. **Verify:**
   - `<ul role="listbox">` present in DOM
   - At least 1 suggestion item visible (expect 3 Springfield addresses)
   - Suggestions show main_text + secondary_text
6. **Pass criteria:** Dropdown visible with suggestions

## Step 3: Select Suggestion via Click

1. `browser_click` on the first suggestion item
2. `browser_snapshot` — capture post-selection state
3. **Verify:**
   - Address input value contains a full address (e.g., "123 Main St, Springfield, IL 62701")
   - Dropdown is dismissed (no listbox visible)
4. **Pass criteria:** Input populated, dropdown gone

## Step 4: Keyboard Navigation

1. Clear the address field (triple-click + delete or select all + type)
2. `browser_type` "456 Test" into address field
3. Wait ~500ms for dropdown
4. `browser_press_key` ArrowDown (highlight first)
5. `browser_press_key` ArrowDown (highlight second)
6. `browser_press_key` Enter (select highlighted)
7. `browser_snapshot` — capture result
8. **Verify:**
   - Address input populated with second suggestion
   - Dropdown dismissed
9. **Pass criteria:** Keyboard selection works

## Step 5: ARIA Accessibility Check

From snapshots collected in Steps 2-4, verify:
- Input: `role="combobox"`, `aria-autocomplete="list"`
- Dropdown open: `aria-expanded="true"`, `aria-controls` set
- Items: `role="option"`
- **Pass criteria:** All ARIA attributes present

## Step 6: Graceful Degradation — Manual Input + Submit

1. Navigate fresh to `http://localhost:4000/book`
2. Fill all required fields:
   - Name: "QA Test User"
   - Phone: "555-0199"
   - Address: "999 Manual Entry Rd" (type without waiting for/selecting autocomplete)
   - Description: "Testing manual address entry"
3. `browser_click` submit button
4. `browser_snapshot` — capture result
5. **Verify:**
   - Form submits successfully (confirmation page or success state)
   - No JS errors in console
6. **Pass criteria:** Manual address accepted, form works without autocomplete selection

## Step 7: Server Health Check

1. `browser_console_messages` — check for JS errors
2. Check dev server logs for 500 errors on `/api/places/autocomplete`
3. **Pass criteria:** No errors

## Bug handling

- If dropdown doesn't appear → check debounce timing, try longer wait
- If selection doesn't populate → check hook's selectSuggestion, document finding
- If form submission fails → check tenant provisioning, fix and retry
- Trivial fixes applied inline; complex issues documented for separate tickets
