# T-022-03 Structure: Proxy Browser QA

## Files

### Created

| File | Purpose |
|------|---------|
| `test/haul_web/live/proxy_qa_test.exs` | End-to-end proxy QA test module |

### Modified

None. This is a test-only ticket.

## Module: HaulWeb.ProxyQATest

```
defmodule HaulWeb.ProxyQATest
  use HaulWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  # Setup: create 2 companies, provision tenants with content
  # Cleanup: drop tenant schemas on_exit

  describe "proxy landing page"
    - renders with tenant business name
    - renders services section
    - links point to proxy namespace

  describe "proxy scan page"
    - mounts LiveView with gallery
    - Book Online link stays in proxy namespace

  describe "proxy booking form"
    - mounts LiveView under proxy
    - form renders and accepts input

  describe "proxy chat"
    - mounts or redirects gracefully under proxy

  describe "cross-tenant isolation"
    - different slug shows different business name
    - content is tenant-specific

  describe "LiveView events under proxy"
    - form submission works (booking form validate event)
end
```

## Dependencies

- `Haul.AI.Provisioner` for tenant content setup
- `Haul.AI.OperatorProfile` for profile struct
- `Haul.AI.Conversation` for provisioner requirement
- `Haul.Accounts.Company` for company creation
- `Haul.Content.{SiteConfig, Service}` for content verification
