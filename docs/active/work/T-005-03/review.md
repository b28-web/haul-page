# T-005-03 Review: QR Code Generation

## Summary

Added a QR code generation endpoint at `GET /scan/qr` that produces downloadable SVG or PNG QR codes pointing to the operator's `/scan` page URL.

## Files Changed

### Created
| File | Purpose |
|------|---------|
| `lib/haul_web/controllers/qr_controller.ex` | Controller with `generate/2` action — parses format/size params, generates QR via eqrcode, returns image with download headers |
| `test/haul_web/controllers/qr_controller_test.exs` | 10 controller tests covering formats, sizes, headers, error cases |

### Modified
| File | Change |
|------|--------|
| `mix.exs` | Added `{:eqrcode, "~> 0.1.10"}` dependency |
| `lib/haul_web/router.ex` | Added `get "/scan/qr", QRController, :generate` route |

## Acceptance Criteria Status

| Criterion | Status |
|-----------|--------|
| QR code generation via Elixir library (eqrcode) | ✓ |
| Accessible at `/scan/qr` | ✓ |
| Outputs SVG or PNG | ✓ (SVG default, PNG via `?format=png`) |
| QR points to `https://{operator-domain}/scan` | ✓ (via `HaulWeb.Endpoint.url() <> "/scan"`) |
| Downloadable | ✓ (Content-Disposition: attachment) |
| Customizable size parameter | ✓ (`?size=100..1000`, default 300) |

## Test Coverage

- **10 new tests**, all passing
- **65 total tests**, 0 failures, no regressions
- Tests cover: default SVG output, PNG output, size parameter, size clamping (min 100, max 1000), invalid format 400 error, Content-Disposition headers for both formats, Cache-Control header, response body validity

## Open Concerns

1. **eqrcode deprecation warnings** — Library uses `Tuple.append/2` and `Range.new/2` which are deprecated in Elixir 1.19. These are upstream issues in eqrcode 0.1.10. Functional but noisy in compilation output. If upstream doesn't fix, could fork or find alternative.

2. **No authentication** — Endpoint is public per ticket spec ("settings page later"). When auth is added (T-004-01+), consider moving this behind operator authentication.

3. **Floating point SVG dimensions** — eqrcode produces widths like `500.0` or `1000.0000000000001` due to internal division by module count. Visually irrelevant for SVG rendering, but slightly imprecise. Could post-process the SVG string to round dimensions if needed.

4. **No rate limiting** — QR generation is CPU-bound (encoding + rendering). Could be abused at scale. Low priority given single-operator deployment model.

## Architecture Notes

- Controller is self-contained — no service module, no database, no Ash resources
- URL construction uses `HaulWeb.Endpoint.url()` which reads from config/runtime.exs — correct across all environments
- Route placed before `live "/scan"` in router to ensure `/scan/qr` matches before the LiveView catch-all
