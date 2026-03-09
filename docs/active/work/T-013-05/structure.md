# T-013-05 Structure: Endorsements CRUD

## Files Modified

### 1. `lib/haul/content/endorsement.ex`
- Add `attribute :sort_order, :integer` (allow_nil? false, default 0, public? true)
- Add `:sort_order` to `:add` action accept list
- Add `:sort_order` to `:edit` action accept list

### 2. `lib/haul_web/router.ex`
- Add `live "/content/endorsements", App.EndorsementsLive` inside authenticated live_session

### 3. `lib/haul_web/components/layouts/admin.html.heex`
- Add sidebar link for Endorsements (hero-chat-bubble-left-right icon)
- Add sidebar link for Gallery (hero-photo icon) — currently missing

## Files Created

### 4. `priv/repo/tenant_migrations/TIMESTAMP_add_endorsement_sort_order.exs`
- Ecto migration: `alter table(:endorsements), add :sort_order, :integer, null: false, default: 0`
- Tenant migration (in tenant schema, not public)

### 5. `lib/haul_web/live/app/endorsements_live.ex`
- Module: `HaulWeb.App.EndorsementsLive`
- `use HaulWeb, :live_view`
- Aliases: ProvisionTenant, Endorsement, Endorsement.Source
- `@source_options` — derived from Source enum values with labels
- `mount/3` — init state, load endorsements sorted by sort_order
- `handle_event/3` — add, edit, validate, save, cancel, delete, confirm_delete, move_up, move_down
- `render/1` — inline form + list layout following ServicesLive pattern
- Private helpers: `load_endorsements/1`, `swap_sort_order/3`

### 6. `test/haul_web/live/app/endorsements_live_test.exs`
- Module: `HaulWeb.App.EndorsementsLiveTest`
- `use HaulWeb.ConnCase, async: false`
- Setup: create_authenticated_context, cleanup_tenants
- Tests: unauthenticated redirect, mount, render existing, add, edit, validate, delete with confirm, reorder up/down, cancel
- Helper: `create_endorsement/2`

## Module Boundaries

- Endorsement resource: domain logic (Ash resource, unchanged interface)
- EndorsementsLive: presentation + CRUD orchestration (AshPhoenix.Form)
- Router: adds route, no new pipelines
- Admin layout: sidebar link only

## Ordering of Changes

1. Migration (sort_order column)
2. Endorsement resource (add sort_order attribute)
3. Router (add route)
4. Admin layout (add sidebar links)
5. EndorsementsLive (LiveView)
6. Tests
