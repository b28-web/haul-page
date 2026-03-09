---
id: T-009-01
story: S-009
title: places-proxy
type: task
status: open
priority: medium
phase: ready
depends_on: [T-001-06]
---

## Context

The Google Places API key must stay server-side. Build a thin proxy endpoint that the booking form's LiveView calls to get autocomplete suggestions. Uses `req` (already a transitive dep via Phoenix) — no dedicated Google API client library needed.

## Acceptance Criteria

- `GET /api/places/autocomplete?input=...` endpoint (JSON response)
- Controller calls Google Places Autocomplete (New) API via `Req.get/2`
- `GOOGLE_PLACES_API_KEY` read from env in `runtime.exs`
- Response shaped to `[%{place_id, description, structured_formatting}]` — only fields the frontend needs
- Rate limiting: debounce is client-side (LiveView hook), but server rejects if `input` < 3 chars
- Returns empty list (not error) if API key is missing or API returns error — graceful degradation
- Test with a mock (Req test adapter or Bypass) — no live Google calls in CI
- API key restricted to Places API in Google Cloud console (documented in DEPLOYMENT.md)
