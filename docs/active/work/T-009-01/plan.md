# T-009-01 Plan: Places Proxy

## Step 1: Places behaviour and sandbox adapter
- Create `lib/haul/places.ex` with behaviour and dispatch
- Create `lib/haul/places/sandbox.ex` with static responses
- Add `config :haul, :places_adapter, Haul.Places.Sandbox` to `config/test.exs`
- Verify: `mix compile`

## Step 2: Google adapter
- Create `lib/haul/places/google.ex`
- POST to Google Places (New) API with Req
- Shape response to match frontend contract
- Graceful degradation on all errors
- Add API key config block to `config/runtime.exs`
- Verify: `mix compile`

## Step 3: Controller and route
- Create `lib/haul_web/controllers/places_controller.ex`
- Add `/api` scope to router with `GET /places/autocomplete`
- Validate input param, delegate to `Haul.Places.autocomplete/1`
- Verify: `mix compile`

## Step 4: Tests
- Create `test/haul_web/controllers/places_controller_test.exs`
  - Missing input → 200 with empty suggestions
  - Short input (< 3 chars) → 200 with empty suggestions
  - Valid input → 200 with suggestions from sandbox
- Create `test/haul/places/google_test.exs`
  - Test `format_suggestions/1` with realistic Google API response
  - Test empty/malformed response handling
- Verify: `mix test`

## Step 5: Final verification
- Run full test suite
- Check formatting: `mix format`

## Testing Strategy
- Controller tests: use sandbox adapter (no HTTP calls)
- Google adapter tests: unit test response shaping only (no live API calls)
- No Bypass needed — adapter pattern handles isolation
