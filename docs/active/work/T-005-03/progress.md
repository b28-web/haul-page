# T-005-03 Progress: QR Code Generation

## Completed Steps

### Step 1: Add eqrcode dependency ✓
- Added `{:eqrcode, "~> 0.1.10"}` to mix.exs
- `mix deps.get` succeeded
- Library compiles with deprecation warnings (Tuple.append, Range.new) — upstream issue, not blocking

### Step 2: Create QRController ✓
- Created `lib/haul_web/controllers/qr_controller.ex`
- Single `generate/2` action with format/size param parsing
- SVG and PNG output via EQRCode.svg/2 and EQRCode.png/2
- Content-Disposition attachment headers for download
- Cache-Control public header (24h)
- Size clamping 100-1000, default 300
- 400 response for invalid format

### Step 3: Add route ✓
- Added `get "/scan/qr", QRController, :generate` to router
- Placed before `live "/scan"` for correct route matching

### Step 4: Write controller tests ✓
- Created `test/haul_web/controllers/qr_controller_test.exs`
- 10 tests covering: default SVG, PNG format, size param, size clamping (min/max), invalid format 400, Content-Disposition headers (SVG/PNG), Cache-Control header, body validity

### Step 5: Full test suite ✓
- 65 tests, 0 failures
- No regressions

## Deviations from Plan

None. Implementation followed the plan exactly.
