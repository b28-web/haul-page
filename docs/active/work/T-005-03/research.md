# T-005-03 Research: QR Code Generation

## Ticket Summary

Generate QR codes server-side pointing to the operator's `/scan` URL. Accessible at `/scan/qr`, outputs SVG or PNG, downloadable, customizable size via query param.

## Codebase Mapping

### Router (`lib/haul_web/router.ex`)
- Two pipelines: `:browser` (HTML/session/CSRF) and `:api` (JSON)
- Landing page: `GET /` -> PageController :home
- Scan page: `live /scan` -> ScanLive
- Health check: `GET /healthz`
- No existing `/scan/qr` route

### Scan Page (`lib/haul_web/live/scan_live.ex`)
- LiveView at `/scan` — hero, gallery, endorsements, footer CTA
- Loads operator config via `Application.get_env(:haul, :operator)`
- Loads content via `Haul.Content.Loader` (persistent_term cache)
- Uses root layout, skips app layout

### Controller Patterns
- `PageController`: reads operator config, assigns, renders template
- `HealthController`: custom content-type via `put_resp_content_type/2` + `send_resp/3`
- Both patterns directly applicable — QR needs custom content-type (SVG/PNG) and raw byte response

### URL Configuration
- Dev: `http://localhost:4000` via config.exs
- Prod: `https://{PHX_HOST}` via runtime.exs (PHX_HOST env var)
- Access via `HaulWeb.Endpoint.url()` — returns full base URL

### Dependencies (mix.exs)
- No QR library currently installed
- Jason available for JSON (not needed here)
- No image processing libraries present
- Candidate: `eqrcode` — Elixir-native, SVG + PNG output, lightweight, maintained

### Content System (`lib/haul/content/loader.ex`)
- JSON files in `priv/content/` loaded at startup into persistent_term
- Not needed for QR — generation is stateless, computed from endpoint URL

### Test Patterns
- `HaulWeb.ConnCase` for controller tests
- `Phoenix.LiveViewTest` for LiveView tests
- Scan page tests exist at `test/haul_web/live/scan_live_test.exs`
- Pattern: `get(conn, path)` -> assert status + body content

## Constraints & Assumptions

1. **No database needed** — QR encodes a URL derived from endpoint config
2. **No LiveView needed** — stateless generation, pure controller action
3. **Target URL:** `HaulWeb.Endpoint.url() <> "/scan"` — always points to the scan page
4. **eqrcode library:** v0.1.10 supports `EQRCode.encode/1` -> `EQRCode.svg/2` and `EQRCode.png/2`
5. **Format negotiation:** query param (`?format=svg` or `?format=png`), not Accept header — simpler for operators
6. **Size param:** integer query param, applies to both SVG viewBox and PNG pixel dimensions
7. **Download:** `Content-Disposition: attachment` header makes browser download instead of display

## Dependencies (ticket)

- T-005-01 (scan-page-layout): DONE — `/scan` route and LiveView exist
- T-005-02 (gallery-data): DONE — content loader exists (not directly needed but confirms scan page is complete)

## Open Questions

- Should `/scan/qr` be behind authentication? Ticket says "via a settings page (later)" suggesting public for now
- Default size? 200px is standard for print QR codes but 300-400px may be better for flyers
- Should SVG include a white background or be transparent? Print materials need white bg
- Cache headers? QR doesn't change unless domain changes — could cache aggressively
