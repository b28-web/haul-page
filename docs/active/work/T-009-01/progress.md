# T-009-01 Progress: Places Proxy

## Completed

### Step 1: Places behaviour and sandbox adapter
- Created `lib/haul/places.ex` — behaviour + adapter dispatch
- Created `lib/haul/places/sandbox.ex` — static suggestions, process notification
- Added `config :haul, :places_adapter, Haul.Places.Sandbox` to `config/test.exs`
- Compiles clean

### Step 2: Google adapter
- Created `lib/haul/places/google.ex` — POST to Google Places (New) API via Req
- Shapes response: extracts `placeId`, `text.text`, `structuredFormat` → flat map
- Graceful degradation: missing key, API error, network error → all return `{:ok, []}`
- Added API key config block to `config/runtime.exs` (conditional, outside prod block)

### Step 3: Controller and route
- Created `lib/haul_web/controllers/places_controller.ex` — 8 lines, validates input length
- Added `/api` scope to router with `GET /places/autocomplete`
- Compiles clean

### Step 4: Tests
- Created `test/haul_web/controllers/places_controller_test.exs` — 7 tests
- Created `test/haul/places/google_test.exs` — 6 tests for response shaping
- All 13 new tests pass

### Step 5: Final verification
- Full test suite: 191 tests, 0 failures
- All new files formatted correctly
- No deviations from plan
