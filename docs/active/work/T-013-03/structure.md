# T-013-03 Structure: Services CRUD

## Files to Create

### 1. `lib/haul_web/live/app/services_live.ex`

Main LiveView module for services CRUD. Single module, no LiveComponents.

**Public interface:**
- `mount/3` — load all services for tenant, initialize socket assigns
- `handle_event("add", ...)` — open modal with empty AshPhoenix.Form for_create
- `handle_event("edit", ...)` — open modal with AshPhoenix.Form for_update
- `handle_event("validate", ...)` — real-time form validation
- `handle_event("save", ...)` — submit form (create or update)
- `handle_event("delete", ...)` — delete service with minimum-1 check
- `handle_event("confirm_delete", ...)` — confirmed deletion
- `handle_event("move_up", ...)` — swap sort_order with previous item
- `handle_event("move_down", ...)` — swap sort_order with next item
- `handle_event("close_modal", ...)` — close add/edit modal

**Socket assigns:**
- `services` — list of all services (sorted by sort_order)
- `tenant` — derived from current_company.slug
- `ash_form` — AshPhoenix.Form (nil when modal closed)
- `form` — Phoenix form (nil when modal closed)
- `modal_title` — "Add Service" or "Edit Service"
- `delete_target` — service pending deletion confirmation (nil normally)

**Template (inline `render/1`):**
- Header with title + "Add Service" button
- Service list: cards/rows with icon, title, description, up/down arrows, edit/delete buttons
- Modal: form with title, description, icon select, active checkbox
- Delete confirmation dialog

### 2. `test/haul_web/live/app/services_live_test.exs`

LiveView tests covering:
- Mount: renders service list
- Add: creates new service via modal form
- Edit: updates existing service via modal form
- Delete: removes service with confirmation
- Delete blocked: cannot delete last service
- Reorder: move_up/move_down updates sort_order
- Validation: form shows errors for missing required fields

## Files to Modify

### 3. `lib/haul_web/router.ex`

Add route in authenticated admin scope:
```elixir
live "/content/services", App.ServicesLive
```

### 4. `lib/haul_web/components/layouts/admin.html.heex`

Update sidebar navigation to include Services link under Content section:
- Add `Services` nav item pointing to `/app/content/services`
- Show as sub-item under Content section
- Active state when path matches

## Module Boundaries

```
Router
  └─ /app/content/services → App.ServicesLive
       ├─ reads: Ash.read!(Service, tenant: tenant)
       ├─ creates: AshPhoenix.Form.for_create(Service, :add, tenant: tenant)
       ├─ updates: AshPhoenix.Form.for_update(service, :edit)
       ├─ deletes: Ash.destroy!(service)
       └─ reorder: Ash.update!(service, :edit, %{sort_order: n})
```

No new domain logic needed — Service resource already has all required actions and fields. The LiveView is the only new module.

## Ordering of Changes

1. Router (add route) — enables navigation to new page
2. Admin layout (add sidebar link) — enables discovery
3. ServicesLive (main implementation) — the feature
4. Tests — verify all acceptance criteria

## Icon Options (hardcoded list in ServicesLive)

```elixir
@icon_options [
  {"Truck", "hero-truck"},
  {"Home", "hero-home-modern"},
  {"Wrench", "hero-wrench-screwdriver"},
  {"Trash", "hero-trash"},
  {"Building", "hero-building-office"},
  {"Tree", "hero-sun"},
  {"Box", "hero-cube"},
  {"Sparkles", "hero-sparkles"},
  {"Shield", "hero-shield-check"},
  {"Clock", "hero-clock"},
  {"Map Pin", "hero-map-pin"},
  {"Phone", "hero-phone"},
  {"Star", "hero-star"},
  {"Bolt", "hero-bolt"},
  {"Arrow Path", "hero-arrow-path"}
]
```
