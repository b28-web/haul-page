# T-009-01 Design: Places Proxy

## Decision: Direct Controller + Module

### Approach
Thin controller at `/api/places/autocomplete` that delegates to a `Haul.Places` module. The module handles API calls and response shaping. A sandbox adapter for test/dev.

### Why This Approach
1. **Adapter pattern** — consistent with SMS and Payments patterns in the codebase
2. **Testable** — swap adapter in test.exs, no mocking library needed
3. **Simple** — no GenServer, no caching, no rate limiting beyond min-length check

### Alternatives Rejected

**A) Controller-only (inline Req call)**
Simpler but untestable without Bypass or Req mocking. Breaks project conventions.

**B) LiveView-only (no HTTP endpoint)**
Could use `handle_event` in BookingLive directly. Rejected because:
- Couples proxy logic to LiveView
- Can't reuse endpoint from other contexts
- AC explicitly specifies `GET /api/places/autocomplete` endpoint

**C) GenServer with caching**
Over-engineering. Google Places API is fast. Client debounce handles rate limiting.

### API Design

**Endpoint:** `GET /api/places/autocomplete?input=...`

**Validation:**
- `input` param required, min 3 chars
- Missing/short input → `{"suggestions": []}`

**Response shape:**
```json
{
  "suggestions": [
    {
      "place_id": "ChIJ...",
      "description": "123 Main St, Springfield, IL, USA",
      "structured_formatting": {
        "main_text": "123 Main St",
        "secondary_text": "Springfield, IL, USA"
      }
    }
  ]
}
```

**Note on AC:** The AC says `GET` endpoint but Google Places (New) API is actually POST. The proxy receives GET from frontend and makes POST to Google. The AC also says response shaped to `[%{place_id, description, structured_formatting}]` — we wrap in `{"suggestions": [...]}` for cleanliness.

### Adapter Pattern

```
Haul.Places (behaviour + dispatch)
├── Haul.Places.Google   — production, calls Google API via Req
└── Haul.Places.Sandbox  — dev/test, returns static suggestions
```

Config:
- `config :haul, :places_adapter, Haul.Places.Sandbox` (default + test)
- `runtime.exs`: if `GOOGLE_PLACES_API_KEY` set → `config :haul, :places_adapter, Haul.Places.Google`

### Error Handling
- Missing API key → empty list (logged as warning once at startup? No — just check at call time)
- Google API error → empty list + Logger.warning
- Network error → empty list + Logger.warning
- All errors are swallowed to match AC's "graceful degradation"
