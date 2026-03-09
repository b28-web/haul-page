# T-010-03 Structure: Smoke Test

## Files Created

### `test/haul_web/smoke_test.exs`

New test file. Single module `HaulWeb.SmokeTest`.

```
defmodule HaulWeb.SmokeTest
  use HaulWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  aliases:
    - Haul.Accounts.Company
    - Haul.Accounts.Changes.ProvisionTenant
    - Haul.Content.Seeder

  setup:
    - Create company from operator config
    - Derive tenant, seed content
    - on_exit cleanup

  tests:
    - "GET /healthz returns 200"
    - "GET / renders landing page"
    - "GET /scan mounts scan LiveView"
    - "GET /book mounts booking LiveView"
    - "GET /scan/qr returns QR image"
```

## Files Modified

None. This is a purely additive change — one new test file.

## Dependencies

- Requires T-010-01 (fix-booking-crash) — ensures `/book` doesn't crash on mount
- Requires T-010-02 (gallery-placeholders) — ensures `/scan` gallery renders with placeholder images

Both are listed as `depends_on` in the ticket frontmatter.

## Module Boundaries

No new modules, no new public interfaces. The test file imports existing test support modules (`ConnCase`, `LiveViewTest`) and existing application modules (`Company`, `ProvisionTenant`, `Seeder`).
