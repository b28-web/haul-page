# T-013-02 Review: Site Config Editor

## Summary

Implemented a LiveView form at `/app/content/site` that lets operators edit their site configuration through the admin UI. The form reads/writes to the Content.SiteConfig Ash resource, scoped to the current tenant.

## Files Changed

### Created
- `lib/haul_web/live/app/site_config_live.ex` — LiveView with create-or-update form pattern, real-time validation, grouped field layout
- `test/haul_web/live/app/site_config_live_test.exs` — 8 tests covering auth, create, update, validation, persistence

### Modified
- `lib/haul_web/router.ex` — added `live "/content/site", App.SiteConfigLive` to authenticated live_session

## Acceptance Criteria Verification

| Criterion | Status |
|-----------|--------|
| `/app/content/site` LiveView form | Done |
| Fields: business_name, phone, email, tagline, service_area, primary_color | Done (plus address, coupon_text, meta_description) |
| Reads/writes to Content.SiteConfig (tenant-scoped) | Done |
| Real-time validation (LiveView form bindings) | Done — phx-change="validate" |
| Save persists immediately | Done — AshPhoenix.Form.submit |
| Success flash: "Site settings updated" | Done |
| Mobile-friendly form layout | Done — single column, responsive grid |

## Test Coverage

8 new tests:
1. Unauthenticated redirect to /app/login
2. Form renders all field labels
3. Create new config with valid data shows flash
4. Missing required fields don't show success flash
5. Existing config values populate form
6. Update existing config persists correctly
7. Real-time validation renders without error for valid data
8. Persisted values visible on page reload

Full suite: 258 tests, 0 failures.

## Design Decisions

- **Create-or-update pattern**: Detects existing SiteConfig on mount. Uses `for_create` for new tenants, `for_update` for existing. After first create, switches to update mode.
- **Extended field set**: Added address, coupon_text, meta_description beyond the 6 AC fields. Zero additional effort, improves utility.
- **Omitted logo_url**: Requires file upload UI, out of scope for this ticket.
- **Grouped layout**: Business Info → Location → Appearance → SEO sections with heading labels.

## Open Concerns

- **No navigation link to `/app/content/site`**: The sidebar links to `/app/content` (DashboardLive placeholder). A future ticket should make `/app/content` a content management hub with links to site settings, services, gallery, etc.
- **Color picker**: primary_color is a plain text input. Could be enhanced with a color picker component later.
- **Logo upload**: logo_url field exists on SiteConfig but is not exposed in this form. Needs a file upload implementation (separate ticket).
