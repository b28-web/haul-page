# T-005-03 Structure: QR Code Generation

## Files to Create

### `lib/haul_web/controllers/qr_controller.ex`
New controller module with single `generate/2` action.

```
defmodule HaulWeb.QRController do
  use HaulWeb, :controller

  def generate(conn, params)
    - Parse format (default "svg") and size (default 300, clamp 100-1000)
    - Build URL: HaulWeb.Endpoint.url() <> "/scan"
    - Encode with EQRCode.encode/1
    - Branch on format:
      - "svg" -> EQRCode.svg/2 with width option, content-type image/svg+xml
      - "png" -> EQRCode.png/2 with width option, content-type image/png
      - other -> 400 bad request
    - Set Content-Disposition: attachment with filename
    - Set Cache-Control: public, max-age=86400
    - send_resp/3
end
```

### `test/haul_web/controllers/qr_controller_test.exs`
Controller tests using `HaulWeb.ConnCase`.

```
defmodule HaulWeb.QRControllerTest do
  use HaulWeb.ConnCase

  Tests:
  - "GET /scan/qr returns SVG by default"
  - "GET /scan/qr?format=png returns PNG"
  - "GET /scan/qr?size=500 respects size parameter"
  - "GET /scan/qr?format=invalid returns 400"
  - "GET /scan/qr?size=0 clamps to minimum"
  - "GET /scan/qr?size=9999 clamps to maximum"
  - "response includes Content-Disposition header"
  - "response includes Cache-Control header"
end
```

## Files to Modify

### `mix.exs`
Add `{:eqrcode, "~> 0.1.10"}` to deps list.

### `lib/haul_web/router.ex`
Add route inside existing `scope "/", HaulWeb` block:
```elixir
get "/scan/qr", QRController, :generate
```

## Files Unchanged

- `lib/haul_web/live/scan_live.ex` — no changes to scan page
- `lib/haul/content/loader.ex` — no content system changes
- `config/config.exs` — no new config keys needed
- `lib/haul_web/endpoint.ex` — URL generation already works

## Module Boundaries

- `QRController` is self-contained — no service module needed
- Direct dependency on `EQRCode` library only within the controller
- Uses `HaulWeb.Endpoint.url()` for URL construction (existing API)
- No interaction with Ash resources, database, or content system

## Ordering

1. Add eqrcode to mix.exs and fetch deps
2. Create QRController
3. Add route to router
4. Create tests
5. Run tests to verify
