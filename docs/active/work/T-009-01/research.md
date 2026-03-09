# T-009-01 Research: Places Proxy

## Goal
Thin proxy endpoint for Google Places Autocomplete API. Keeps API key server-side.

## Relevant Codebase

### Router (`lib/haul_web/router.ex`)
- `:api` pipeline exists: `plug :accepts, ["json"]`
- Webhook scope uses `:api` pipeline at `/webhooks`
- No existing `/api` scope — need to create one for `GET /api/places/autocomplete`

### Controller Patterns
- `use HaulWeb, :controller` — includes `formats: [:html, :json]`
- JSON responses via `json(conn, data)` from Phoenix.Controller
- Pattern: validate params → call service → return JSON
- WebhookController is the closest analog (JSON API endpoint)

### Runtime Config (`config/runtime.exs`)
- External API keys read conditionally: `if key = System.get_env("KEY") do config ... end`
- Pattern for Places: read `GOOGLE_PLACES_API_KEY`, store in `:haul, :google_places`
- If missing, controller returns empty list (graceful degradation per AC)

### HTTP Client — Req
- `{:req, "~> 0.5"}` in mix.exs
- Used by `Haul.SMS.Twilio` — pattern: `Req.post(url, opts)` → match on `%Req.Response{}`
- For Places: `Req.get!` with query params to Google's endpoint

### Booking LiveView (`lib/haul_web/live/booking_live.ex`)
- Address field at line 189-196: plain `<.input field={@form[:address]}>`
- No autocomplete hook currently wired
- Will need `phx-hook="PlacesAutocomplete"` and a dropdown for suggestions
- **Note:** T-009-02 handles the LiveView integration — this ticket is just the proxy endpoint

### JavaScript Hooks (`assets/js/hooks/`)
- `stripe_payment.js` — pattern: `mounted()`, dataset attrs, `this.pushEvent()`
- Registered in `app.js` line 33: `hooks: {...colocatedHooks, StripePayment}`
- **Note:** Hook for autocomplete is T-009-02's scope, not this ticket

### Test Infrastructure
- `HaulWeb.ConnCase` — `build_conn()`, `json_response(conn, status)`
- No Bypass dep currently; Req test adapter or simple mock module preferred
- Existing pattern: adapter config in `test.exs` (e.g., `:sms_adapter`, `:payments_adapter`)

## Google Places Autocomplete (New) API
- Endpoint: `https://places.googleapis.com/v1/places:autocomplete`
- POST request with JSON body: `{"input": "pizza near", "languageCode": "en"}`
- Auth via header: `X-Goog-Api-Key: API_KEY`
- Response: `{"suggestions": [{"placePrediction": {"placeId": "...", "text": {"text": "..."}, "structuredFormat": {"mainText": {"text": "..."}, "secondaryText": {"text": "..."}}}}]}`
- The "New" API uses POST, not GET (unlike the legacy Autocomplete)

## Constraints
- API key must never reach client
- Graceful degradation: missing key or API error → empty list
- Input < 3 chars → reject server-side (400 or empty list)
- No live Google calls in test suite
- Rate limiting is client-side (debounce in hook) — server just validates min length
