# T-005-03 Plan: QR Code Generation

## Step 1: Add eqrcode dependency

**Action:** Add `{:eqrcode, "~> 0.1.10"}` to `mix.exs` deps
**Verify:** `mix deps.get` succeeds, `mix deps.compile eqrcode` succeeds

## Step 2: Create QRController

**Action:** Create `lib/haul_web/controllers/qr_controller.ex`
- `generate/2` action
- Parse `format` param (default "svg", accept "svg"/"png")
- Parse `size` param (default 300, clamp to 100..1000)
- Build scan URL from `HaulWeb.Endpoint.url() <> "/scan"`
- Encode QR matrix with `EQRCode.encode/1`
- Generate output: `EQRCode.svg/2` or `EQRCode.png/2`
- Set headers: Content-Type, Content-Disposition (attachment), Cache-Control
- Return 400 for invalid format

**Verify:** Module compiles (`mix compile --warnings-as-errors`)

## Step 3: Add route

**Action:** Add `get "/scan/qr", QRController, :generate` to router scope
- Place before `live "/scan"` to ensure specific route matches first

**Verify:** `mix compile`, `mix phx.routes` shows the route

## Step 4: Write controller tests

**Action:** Create `test/haul_web/controllers/qr_controller_test.exs`
- Test default response (SVG format, 200 status)
- Test PNG format
- Test custom size parameter
- Test invalid format returns 400
- Test size clamping (below min, above max)
- Test Content-Disposition header present
- Test Cache-Control header present
- Test SVG contains XML
- Test PNG starts with PNG magic bytes (<<137, 80, 78, 71>>)

**Verify:** `mix test test/haul_web/controllers/qr_controller_test.exs` — all pass

## Step 5: Full test suite

**Action:** Run `mix test` to confirm no regressions
**Verify:** All existing tests still pass

## Commit Strategy

Single commit after all steps pass: "Add QR code generation endpoint at /scan/qr"
