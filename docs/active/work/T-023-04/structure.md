# T-023-04 Structure: Superadmin Browser QA

## Files

### Created

**`test/haul_web/live/admin/superadmin_qa_test.exs`**
- Module: `HaulWeb.Admin.SuperadminQATest`
- `use HaulWeb.ConnCase, async: false`
- `import Phoenix.LiveViewTest`

### Modified

None. This is a test-only ticket.

## Module structure

```elixir
defmodule HaulWeb.Admin.SuperadminQATest do
  use HaulWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  # Aliases for data setup
  alias Haul.Accounts.{Company, Changes.ProvisionTenant}
  alias Haul.Content.{SiteConfig, Service}

  setup do
    on_exit(fn -> cleanup_tenants() end)

    admin_ctx = create_admin_session()
    tenant_ctx = create_company_with_content("qa-target", "QA Target Co")
    tenant_b = create_company_with_content("qa-other", "QA Other Co")
    user_ctx = create_authenticated_context()

    %{
      admin: admin_ctx,
      target: tenant_ctx,
      other: tenant_b,
      user: user_ctx
    }
  end

  # Private helper: creates company + provisions tenant + seeds SiteConfig + Service
  defp create_company_with_content(slug, name) -> %{company, tenant, slug, name}

  describe "superadmin login and dashboard"
    # - Mount /admin with admin session → renders dashboard
    # - Dashboard shows admin email

  describe "accounts list"
    # - Mount /admin/accounts → shows company names
    # - Shows both test companies

  describe "account detail"
    # - Mount /admin/accounts/:slug → company info displayed
    # - Users table rendered
    # - Impersonate button present with correct action URL

  describe "impersonation flow"
    # - POST /admin/impersonate/:slug → redirects to /app
    # - Session keys set correctly
    # - Mount /app with impersonation session → banner visible
    # - Banner shows correct company name and slug
    # - Company content matches impersonated tenant (not admin or other)
    # - POST /admin/exit-impersonation → redirects to /admin/accounts
    # - Session keys cleared after exit

  describe "privilege stacking blocked"
    # - GET /admin with impersonation session → 404
    # - GET /admin/accounts with impersonation session → 404

  describe "security: regular user access"
    # - GET /admin as regular user → 404
    # - GET /admin/accounts/:slug as regular user → 404
    # - GET /admin as unauthenticated → 404
end
```

## Data dependencies

```
setup block
├── create_admin_session()     → admin JWT token for admin routes
├── create_company_with_content("qa-target", ...) → target company + tenant + content
├── create_company_with_content("qa-other", ...)  → second company for isolation check
└── create_authenticated_context()                → regular user for security tests
```

## Boundary

- No production code changes
- Test file only depends on existing helpers in `conn_case.ex`
- `create_company_with_content/2` is a private helper within the test (same pattern as `proxy_qa_test.exs`)
