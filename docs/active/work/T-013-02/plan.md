# T-013-02 Plan: Site Config Editor

## Step 1: Add Route

**File:** `lib/haul_web/router.ex`

Add `live "/content/site", App.SiteConfigLive` to the authenticated live_session block. Replace the placeholder `live "/content", App.DashboardLive` with a proper content route, or add the new route alongside it.

**Verify:** `mix compile` succeeds (will warn about missing module, that's expected).

## Step 2: Create SiteConfigLive

**File:** `lib/haul_web/live/app/site_config_live.ex`

Implement the LiveView:

1. `mount/3`:
   - Derive tenant from `socket.assigns.current_company.slug`
   - Try `Ash.read(SiteConfig, tenant: tenant)` to get existing config
   - If found: `AshPhoenix.Form.for_update(config, :edit, as: "site_config", tenant: tenant)`
   - If not: `AshPhoenix.Form.for_create(SiteConfig, :create_default, as: "site_config", tenant: tenant)`
   - Assign form, ash_form, existing_config, page_title

2. `handle_event("validate", params)`:
   - `AshPhoenix.Form.validate(ash_form, params)`
   - Re-assign form and ash_form

3. `handle_event("save", params)`:
   - `AshPhoenix.Form.submit(ash_form, params: params)`
   - On success: flash "Site settings updated", switch to update form if was create
   - On error: re-assign form with errors

4. `render/1`:
   - Form with phx-change="validate" phx-submit="save"
   - Grouped fields with section headings
   - Save button at bottom

**Verify:** `mix compile` succeeds, dev server renders the form.

## Step 3: Write Tests

**File:** `test/haul_web/live/app/site_config_live_test.exs`

Tests:
1. Unauthenticated access redirects to /app/login
2. Authenticated owner can access the page, sees form fields
3. Save with valid data shows "Site settings updated" flash
4. Save with missing required fields shows validation errors
5. Existing config values populate the form
6. Updated values persist (re-mount shows new values)

**Verify:** `mix test test/haul_web/live/app/site_config_live_test.exs` passes.

## Step 4: Final Verification

- Run full test suite: `mix test`
- Confirm no regressions
