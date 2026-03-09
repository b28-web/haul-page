# T-014-03 Research: Browser QA for CLI Onboarding

## Ticket Summary

Verify that CLI-onboarded operators get a working site. Run `mix haul.onboard` then confirm the new tenant's site is live and functional via browser tests.

## Relevant Code

### Onboarding Pipeline

- `lib/haul/onboarding.ex` (189 lines) — Core orchestration: Company creation → tenant provisioning → content seeding → SiteConfig update → owner user creation. Returns `{:ok, result}` with company, tenant, user, content, existing_company fields.
- `lib/mix/tasks/haul/onboard.ex` (88 lines) — CLI wrapper with `--name`, `--phone`, `--email`, `--area` flags.
- `lib/haul/release.ex` — Production entry point via `Release.onboard/1`.

### Content Seeding

- `lib/haul/content/seeder.ex` (214 lines) — Idempotent seeder reads from `priv/content/defaults/`. Seeds: site_config.yml, 6 services, 4 gallery items, 3 endorsements, 2 pages.
- Default content in `priv/content/defaults/` — professional content, not Lorem Ipsum. Gallery uses SVG placeholders at `/images/gallery/before-N.svg` and `after-N.svg`.

### Tenant Routing

- `lib/haul_web/plugs/tenant_resolver.ex` (118 lines) — Resolution: custom domain → subdomain → fallback. Sets `conn.assigns.current_tenant` and `conn.assigns.tenant`.
- `lib/haul_web/live/auth_hooks.ex` — TenantHook propagates tenant to LiveViews from session.
- Base domain: `Application.get_env(:haul, :base_domain, "haulpage.test")`.

### Public Routes (what renders for a tenant)

- `GET /` → PageController.home — Landing page with business_name, phone, email, tagline, service_area, services grid, coupon strip.
- `live /scan` → ScanLive — Gallery items (before/after), endorsements, phone, CTA.
- `live /book` → BookingLive — Booking form with address, photos, description.
- `live /app/login` → LoginLive — Email/password form for owner access.

### Content Loading

- `lib/haul_web/content_helpers.ex` (84 lines) — `resolve_tenant/0`, `load_site_config/1`, `load_services/1`, `load_gallery_items/1`, `load_endorsements/1`. Falls back to operator config if no DB records.
- **Key issue for testing**: `PageController.home` calls `ContentHelpers.resolve_tenant()` which derives tenant from operator config, NOT from conn.assigns. This means the landing page won't use the test tenant unless we either: (a) configure the operator slug to match, or (b) test via subdomain routing.

### Test Infrastructure

- `test/support/conn_case.ex` — `create_authenticated_context/1`, `log_in_user/2`, `cleanup_tenants/0`.
- `test/haul_web/smoke_test.exs` — Pattern: create company with operator slug, provision tenant, seed content, test routes.
- `test/haul/onboarding_test.exs` — Tests `Haul.Onboarding.run/1` end-to-end.
- `test/haul_web/live/app/login_live_test.exs` — Tests login form rendering and auth.

### Key Pattern from SmokeTest

The smoke test creates a company with the operator config slug so that `ContentHelpers.resolve_tenant()` resolves to the test tenant. This is the pattern to follow — the landing page uses operator config, not subdomain routing, for tenant resolution.

## Constraints

1. Tests must be `async: false` due to tenant schema creation/cleanup.
2. Need `on_exit` cleanup to drop `tenant_*` schemas.
3. The onboarding module generates a random password, so we can't use it for login testing — need to use `create_authenticated_context` pattern or register a known-password user separately.
4. Browser QA here means LiveView test assertions (Phoenix.LiveViewTest), not Playwright MCP — matching the pattern of other browser-qa tickets that have tests.
5. The landing page is server-rendered (PageController), not LiveView — use `get/2` + `html_response/2`.

## Existing Test Coverage

- `onboarding_test.exs` — Tests the pipeline itself (company, tenant, content, user, idempotency).
- `defaults_test.exs` — Validates default content pack structure.
- `smoke_test.exs` — Tests routes render without crashing (but with hardcoded operator slug).
- No existing test that runs onboarding then verifies the resulting site renders correctly with the onboarded content.

## Gap

The missing test is: run `Haul.Onboarding.run/1` → then verify all public pages render correctly with the onboarded operator's content (business name, phone, services, gallery, endorsements) and that the owner can access `/app/login`.
