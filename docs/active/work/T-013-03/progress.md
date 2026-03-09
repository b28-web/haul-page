# T-013-03 Progress: Services CRUD

## Completed Steps

### Step 1: Router + Sidebar Navigation
- Added `live "/content/services", App.ServicesLive` route to authenticated admin scope
- Added Services sub-link in sidebar under Content section (shown when on `/app/content/*` path)
- Site Settings also added as sub-link for consistency

### Step 2: ServicesLive — Full Implementation
- Created `lib/haul_web/live/app/services_live.ex` with complete CRUD:
  - Mount: loads all services for tenant, initializes assigns
  - List view: service cards with icon, title, description, up/down arrows, edit/delete buttons
  - Add: opens inline form with AshPhoenix.Form for_create
  - Edit: opens inline form with AshPhoenix.Form for_update, pre-filled
  - Delete: confirmation dialog, PaperTrail version cleanup, direct SQL delete
  - Reorder: move_up/move_down swap sort_order between adjacent services
  - Cancel: closes form or delete confirmation
  - Icon selector: dropdown with 15 predefined Heroicon options + live preview
  - Active toggle: checkbox on edit form (new services default active)
  - Minimum 1 service enforcement: delete button hidden when only 1 service exists

### Step 3: Tests
- Created `test/haul_web/live/app/services_live_test.exs` with 11 tests
- All tests pass. Full suite: 280 tests, 0 failures.

## Deviations from Plan

1. **No modal component** — used inline card form (show/hide) instead of a modal, since CoreComponents has no `<.modal>`. Simpler and works well.

2. **Direct SQL for delete** — `Ash.destroy` fails because PaperTrail creates FK-constrained version records. Used direct SQL to delete versions then the service record. This is a known limitation of AshPaperTrail with destroy actions.

3. **Test selectors** — used `render_click(event, params)` instead of CSS element selectors, as LiveView renders phx-click attributes as JSON arrays which CSS selectors can't match.
