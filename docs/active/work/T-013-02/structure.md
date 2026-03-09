# T-013-02 Structure: Site Config Editor

## Files to Create

### `lib/haul_web/live/app/site_config_live.ex`

New LiveView module for the site config editor form.

**Public interface:**
- `mount/3` — loads existing SiteConfig or initializes create form
- `handle_event("validate", ...)` — real-time form validation
- `handle_event("save", ...)` — persists changes via AshPhoenix.Form
- `render/1` — form with grouped fields

**Internal:**
- `assign_form/2` — builds AshPhoenix.Form (create or update based on existing record)
- `tenant_from_company/1` — derives tenant schema from company

**Assigns:**
- `@form` — Phoenix form (from `to_form`)
- `@ash_form` — AshPhoenix.Form state
- `@existing_config` — nil or SiteConfig struct (tracks create vs update mode)
- `@page_title` — "Site Settings"

### `test/haul_web/live/app/site_config_live_test.exs`

LiveView tests following DashboardLiveTest patterns.

**Test cases:**
- Unauthenticated redirects to /app/login
- Renders form with empty fields (no existing config)
- Renders form with existing config values
- Validates required fields
- Saves new config (create) with flash
- Updates existing config with flash
- Persists changes (visible on reload)

## Files to Modify

### `lib/haul_web/router.ex`

Add route to the authenticated live_session:
```
live "/content/site", App.SiteConfigLive
```

## Module Boundaries

- `SiteConfigLive` reads/writes via `AshPhoenix.Form` — no direct Ash calls except initial load
- Tenant derivation uses `Haul.Accounts.Changes.ProvisionTenant.tenant_schema/1`
- No new components needed — uses existing `<.input>`, `<.button>` from core_components
- No changes to SiteConfig resource — existing `:create_default` and `:edit` actions suffice

## Ordering

1. Add route to router (quick, enables navigation)
2. Create SiteConfigLive module (core work)
3. Create test file (verification)
