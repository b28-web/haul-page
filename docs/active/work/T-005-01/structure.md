# T-005-01 Structure: Scan Page Layout

## Files Created

### `lib/haul_web/live/scan_live.ex`

LiveView module for the `/scan` page.

```
defmodule HaulWeb.ScanLive do
  use HaulWeb, :live_view

  # Module attributes: @gallery_items, @endorsements (hardcoded data)

  mount/3:
    - Read operator config from Application.get_env(:haul, :operator)
    - Assign: business_name, phone, email, service_area
    - Assign: gallery_items from @gallery_items
    - Assign: endorsements from @endorsements
    - Set page_title

  render/1:
    - Hero section: operator name eyebrow, "Scan to Schedule" h1, phone tel: link, "Book Online" CTA
    - Gallery section: "Our Work" h2, before/after image pairs with captions
    - Endorsements section: "What Customers Say" h2, quote cards with star ratings
    - Footer CTA: "Ready to Book?" with call + book buttons
end
```

**Layout:** `use Phoenix.LiveView, layout: false` — skips app layout, keeps root layout.

### `test/haul_web/live/scan_live_test.exs`

LiveView test module.

```
defmodule HaulWeb.ScanLiveTest do
  use HaulWeb.ConnCase

  Tests:
    - GET /scan returns 200 with scan page
    - Displays operator business name and phone
    - Phone number is a tel: link
    - Contains "Book Online" CTA linking to /book
    - Renders gallery section with "Our Work" heading
    - Renders endorsement section with customer names
    - Renders star ratings for endorsements
end
```

### `priv/static/images/gallery/` (directory)

Placeholder images for before/after gallery. Will contain simple placeholder files or be referenced as external URLs initially.

## Files Modified

### `lib/haul_web/router.ex`

Add LiveView route in the browser scope:

```diff
  scope "/", HaulWeb do
    pipe_through :browser

    get "/", PageController, :home
+   live "/scan", ScanLive
  end
```

## Module Boundaries

- `HaulWeb.ScanLive` — self-contained LiveView, no external dependencies beyond operator config
- Gallery/endorsement data lives as module attributes in `ScanLive` — no separate data module
- Uses `HaulWeb.CoreComponents` (auto-imported) for `<.icon>` and `<.button>`
- No new components created — all markup is inline in the template

## Ordering

1. Create `lib/haul_web/live/scan_live.ex` (module + template)
2. Add route to `lib/haul_web/router.ex`
3. Create test file `test/haul_web/live/scan_live_test.exs`
4. Verify with `mix test`

## No Changes To

- `config/config.exs` — gallery/endorsement data stays in module, not config
- `assets/css/app.css` — all styling uses existing Tailwind tokens
- `lib/haul_web/components/core_components.ex` — no new components needed
- `lib/haul_web.ex` — macros already support LiveView
