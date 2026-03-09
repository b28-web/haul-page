# T-009-01 Review: Places Proxy

## Summary

Implemented a server-side proxy for Google Places Autocomplete (New) API. The API key stays server-side; the frontend (T-009-02) will call `GET /api/places/autocomplete?input=...` to get suggestions.

## Files Created

| File | Purpose |
|------|---------|
| `lib/haul/places.ex` | Behaviour + adapter dispatch (18 LOC) |
| `lib/haul/places/google.ex` | Google Places (New) API adapter (65 LOC) |
| `lib/haul/places/sandbox.ex` | Dev/test adapter with static data (40 LOC) |
| `lib/haul_web/controllers/places_controller.ex` | HTTP endpoint (12 LOC) |
| `test/haul_web/controllers/places_controller_test.exs` | Controller tests — 7 tests |
| `test/haul/places/google_test.exs` | Response shaping tests — 6 tests |

## Files Modified

| File | Change |
|------|--------|
| `lib/haul_web/router.ex` | Added `/api` scope with places autocomplete route |
| `config/runtime.exs` | Added `GOOGLE_PLACES_API_KEY` env var block |
| `config/test.exs` | Added `:places_adapter` sandbox config |

## Test Coverage

- **13 new tests**, all passing
- Controller: missing input, empty input, short input (1 char, 2 chars), exact 3 chars, valid input, sandbox message receipt
- Google adapter: typical response, empty suggestions, missing key, nil input, non-place suggestions (query suggestions filtered), missing fields

## Acceptance Criteria Status

| Criterion | Status |
|-----------|--------|
| `GET /api/places/autocomplete?input=...` endpoint | Done |
| Controller calls Google Places API via Req | Done (via adapter) |
| `GOOGLE_PLACES_API_KEY` from env in runtime.exs | Done |
| Response shaped to `[%{place_id, description, structured_formatting}]` | Done |
| Server rejects if input < 3 chars | Done (returns empty list) |
| Returns empty list if key missing or API error | Done |
| Test with mock (no live Google calls) | Done (adapter pattern) |
| API key restriction documented in DEPLOYMENT.md | Not done — DEPLOYMENT.md doesn't exist yet. Document when deploy docs are created. |

## Open Concerns

1. **DEPLOYMENT.md note:** The AC mentions documenting API key restriction in DEPLOYMENT.md. This file doesn't exist yet. Should be addressed when deploy documentation is created (possibly T-011-01 onboarding-runbook).

2. **Google Places (New) API uses POST, not GET:** The AC says "calls Google Places Autocomplete (New) API" — the New API uses POST with JSON body, which is what we implemented. The proxy itself exposes GET to the frontend, which is correct.

3. **No Bypass dependency needed:** The adapter pattern avoids the need for Bypass or Req test adapters. Tests use the sandbox adapter which is consistent with SMS and Payments patterns.

## No Known Bugs or Regressions

Full suite: 191 tests, 0 failures. No warnings in new code.
