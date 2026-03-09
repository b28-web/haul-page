# T-009-01 Structure: Places Proxy

## Files to Create

### `lib/haul/places.ex`
- Behaviour module with `@callback autocomplete(input :: String.t()) :: {:ok, list(map())} | {:error, term()}`
- Public `autocomplete/1` that dispatches to configured adapter
- Reads adapter from `Application.get_env(:haul, :places_adapter, Haul.Places.Sandbox)`

### `lib/haul/places/google.ex`
- `@behaviour Haul.Places`
- `autocomplete/1` — POST to `https://places.googleapis.com/v1/places:autocomplete`
- Reads API key from `Application.get_env(:haul, :google_places_api_key)`
- Shapes response: extract `suggestions[].placePrediction` → `%{place_id, description, structured_formatting}`
- Returns `{:ok, []}` on any error (graceful degradation)

### `lib/haul/places/sandbox.ex`
- `@behaviour Haul.Places`
- Returns static list of 3 fake suggestions
- Sends `{:places_autocomplete, input}` to `self()` for test assertions

### `lib/haul_web/controllers/places_controller.ex`
- `use HaulWeb, :controller`
- `autocomplete(conn, params)` action
- Validates `input` param (required, >= 3 chars)
- Calls `Haul.Places.autocomplete(input)`
- Returns `json(conn, %{suggestions: suggestions})`

### `test/haul_web/controllers/places_controller_test.exs`
- `use HaulWeb.ConnCase, async: true`
- Tests: missing input, short input, valid input returns suggestions
- Uses sandbox adapter (default in test)

### `test/haul/places/google_test.exs`
- Unit test for response shaping
- Tests the `format_suggestions/1` helper with raw Google API response shapes

## Files to Modify

### `lib/haul_web/router.ex`
- Add `/api` scope with `:api` pipeline
- Route: `get "/places/autocomplete", PlacesController, :autocomplete`

### `config/runtime.exs`
- Add Google Places API key block (conditional, like Stripe/Twilio pattern)

### `config/test.exs`
- Add `config :haul, :places_adapter, Haul.Places.Sandbox`

## Module Boundaries
- `Haul.Places` — business logic boundary. Controller never calls Google directly.
- `HaulWeb.PlacesController` — HTTP boundary. Validates params, delegates to `Haul.Places`.
- Adapters are internal to `Haul.Places` — not exposed beyond the behaviour dispatch.
