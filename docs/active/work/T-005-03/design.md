# T-005-03 Design: QR Code Generation

## Decision: Simple Controller + eqrcode Library

### Approach

A single controller action at `GET /scan/qr` that generates a QR code encoding the operator's scan page URL. Format (SVG/PNG) and size controlled via query params. Response is the raw image with appropriate content-type and download headers.

### Options Evaluated

#### Option A: Controller action with eqrcode (CHOSEN)
- Add `eqrcode` dep, create `QRController` with one action
- Query params: `?format=svg|png&size=300`
- Returns raw image bytes with content-type and Content-Disposition headers
- **Pros:** Simple, stateless, no database, follows existing controller patterns
- **Cons:** None significant — this is a straightforward feature

#### Option B: LiveView page with embedded QR
- Render QR inline on a LiveView page with download button
- **Pros:** Richer UI, could show preview alongside download link
- **Cons:** Over-engineered for "download a QR code." Ticket says "settings page (later)" — this is the simple version. LiveView adds unnecessary complexity for serving a static image.
- **Rejected:** YAGNI. The ticket asks for a downloadable QR, not a UI page.

#### Option C: Pre-generate and serve as static file
- Generate QR at deploy time, serve from `priv/static`
- **Pros:** Zero runtime cost
- **Cons:** Can't customize size via query param. URL depends on runtime config (PHX_HOST), not available at build time. Breaks the acceptance criteria.
- **Rejected:** Can't satisfy size customization or runtime URL requirements.

### Library Choice: eqrcode

`eqrcode` ~> 0.1.10:
- Pure Elixir, no NIFs or external dependencies
- `EQRCode.encode(string)` -> QR matrix
- `EQRCode.svg(matrix, opts)` -> SVG string (supports `width` option)
- `EQRCode.png(matrix, opts)` -> PNG binary (supports `width` option)
- Maintained, widely used in Elixir ecosystem
- ~20KB dep, no transitive dependencies

No other serious contenders in Elixir ecosystem. `qr_code` exists but is less mature.

### Route Design

```
GET /scan/qr?format=svg&size=300
```

- **format**: `svg` (default) or `png`
- **size**: integer pixels, default 300, min 100, max 1000
- Response headers:
  - `Content-Type: image/svg+xml` or `image/png`
  - `Content-Disposition: attachment; filename="qr-scan.svg"` (or .png)
  - `Cache-Control: public, max-age=86400` (QR rarely changes)

### URL Construction

```elixir
url = HaulWeb.Endpoint.url() <> "/scan"
# Dev:  "http://localhost:4000/scan"
# Prod: "https://operator-domain.com/scan"
```

Uses `HaulWeb.Endpoint.url()` which reads from config — correct in all environments.

### SVG Customization

eqrcode SVG output is basic black-on-white. For print materials this is ideal — operators send to print shops. No need for dark-theme styling on the QR itself. White background included in SVG for print compatibility.

### Error Handling

- Invalid format -> 400 with plain text error
- Invalid size (non-integer, out of range) -> 400 with plain text error
- No complex error pages needed — this endpoint is for operators, not end users

### Security

- Public endpoint, no auth needed (ticket says "settings page later")
- No user input beyond format/size query params — no injection risk
- Size clamped to 100-1000 to prevent resource abuse

### Testing Strategy

- Controller tests with `HaulWeb.ConnCase`
- Test default params (SVG, 300px)
- Test PNG format
- Test custom size
- Test invalid format returns 400
- Test invalid size returns 400
- Test response headers (content-type, content-disposition)
- Test SVG output contains valid XML
- Test PNG output starts with PNG magic bytes
