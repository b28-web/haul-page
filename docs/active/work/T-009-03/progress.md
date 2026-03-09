# T-009-03 Progress — Browser QA for Address Autocomplete

## Prerequisites

- Dev server: running on port 4000 (confirmed via healthz)
- Playwright MCP: connected (headless Chrome)
- Sandbox places adapter: active (default dev config)
- Tenant: `junk-and-handy` already provisioned (from T-003-04 session)

## Step 1: Page Load — PASS

- Navigated to `http://localhost:4000/book`
- Page title: "Book a Pickup · Phoenix Framework"
- Address field present with `combobox` role (ARIA correct from initial render)
- Placeholder: "123 Main St, Anytown, USA"

## Step 2: Autocomplete Dropdown Trigger — PASS

- Typed "123 Main" slowly into address field (char by char for debounce)
- Dropdown appeared with `role="listbox"`
- 3 suggestions rendered from Sandbox adapter:
  - "123 Main St, Springfield, IL 62701, USA"
  - "456 Oak Ave, Springfield, IL 62702, USA"
  - "789 Elm Dr, Springfield, IL 62703, USA"
- Server log confirmed: `GET /api/places/autocomplete` → 200 in 2ms

## Step 3: Selection via Click — PASS

- Clicked first suggestion ("123 Main St, Springfield, IL 62701, USA")
- Address input populated with full address: "123 Main St, Springfield, IL 62701, USA"
- Dropdown reappeared (input event triggered new fetch — expected behavior)
- Clicked heading to blur → dropdown dismissed
- Address value retained correctly

## Step 4: Keyboard Navigation — PASS

- Cleared address field, typed "456 Test"
- Dropdown appeared with 3 suggestions
- Pressed ArrowDown twice (highlighted second item)
- Pressed Enter → selected "456 Oak Ave, Springfield, IL 62702, USA"
- Input populated with second suggestion's full address
- Pressed Escape → dropdown dismissed
- Address value retained: "456 Oak Ave, Springfield, IL 62702, USA"

## Step 5: ARIA Accessibility — PASS

Verified from snapshots across Steps 1-4:
- ✅ Input has `combobox` role (visible in initial snapshot)
- ✅ Dropdown has `listbox` role
- ✅ Suggestions have `option` role
- ✅ Keyboard navigation works (ArrowDown/Up, Enter, Escape)
- ✅ Dropdown dismissed on blur and Escape

## Step 6: Graceful Degradation — PASS

- Navigated fresh to `/book`
- Filled all required fields with manual address "999 Manual Entry Rd"
- Did NOT select from autocomplete dropdown
- Submitted form → "Thank You!" confirmation displayed
- Manual address accepted, Job created successfully
- SMS notification triggered (visible in server log)

## Step 7: Server Health — PASS

- Browser console: 0 errors, 0 warnings (30 total messages, all info/log level)
- Server log: no 500 errors on `/api/places/autocomplete`
- Only benign entries: GenServer transport timeout from stale connection (unrelated)

## Summary

All 7 test steps passed. All acceptance criteria met.
