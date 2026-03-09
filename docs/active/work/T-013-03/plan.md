# T-013-03 Plan: Services CRUD

## Step 1: Router + Sidebar Navigation

**Changes:**
- `lib/haul_web/router.ex` — add `live "/content/services", App.ServicesLive` in authenticated scope
- `lib/haul_web/components/layouts/admin.html.heex` — add Services link in sidebar

**Verify:** App compiles (route exists but LiveView not yet — will fail at runtime until Step 2)

## Step 2: ServicesLive — List View + Mount

**Changes:**
- Create `lib/haul_web/live/app/services_live.ex`
- Implement `mount/3`: derive tenant, load services via `Ash.read!`, assign to socket
- Implement `render/1`: header with "Services" title + "Add Service" button, service cards with icon/title/description, up/down arrows, edit/delete buttons
- Stub all event handlers (return `{:noreply, socket}`)

**Verify:** Navigate to `/app/content/services`, see service list rendered with correct data

## Step 3: Add Service (Modal + Form)

**Changes:**
- Implement `handle_event("add", ...)`: create `AshPhoenix.Form.for_create(Service, :add, ...)`, open modal
- Implement `handle_event("validate", ...)`: validate form
- Implement `handle_event("save", ...)` for create case: submit form, reload services, close modal, flash
- Implement `handle_event("close_modal", ...)`: clear form assigns
- Add modal template with form fields: title, description, icon select, active checkbox

**Verify:** Click "Add Service", fill form, submit → new service appears in list

## Step 4: Edit Service

**Changes:**
- Implement `handle_event("edit", ...)`: load service, create `AshPhoenix.Form.for_update(service, :edit)`, open modal
- Reuse save handler (detect create vs update from form type)

**Verify:** Click edit on existing service → modal pre-filled → save updates service

## Step 5: Delete Service

**Changes:**
- Implement `handle_event("delete", ...)`: set `delete_target` assign, show confirmation
- Implement `handle_event("confirm_delete", ...)`: check count > 1, call `Ash.destroy!`, reload, flash
- Implement `handle_event("cancel_delete", ...)`: clear delete_target
- Add delete confirmation dialog in template
- Disable delete button when only 1 service exists

**Verify:** Delete works with confirmation. Cannot delete last service (button disabled + backend check).

## Step 6: Reorder (Move Up/Down)

**Changes:**
- Implement `handle_event("move_up", ...)`: swap sort_order with previous service, save both, reload
- Implement `handle_event("move_down", ...)`: swap sort_order with next service, save both, reload
- Disable up arrow on first item, down arrow on last item

**Verify:** Reorder services → landing page reflects new order

## Step 7: Tests

**Changes:**
- Create `test/haul_web/live/app/services_live_test.exs`
- Test mount renders services
- Test add creates new service
- Test edit updates service
- Test delete removes service
- Test cannot delete last service
- Test move_up/move_down reorders
- Test form validation errors

**Verify:** `mix test test/haul_web/live/app/services_live_test.exs` — all pass

## Testing Strategy

| Scenario | Type | Criteria |
|---|---|---|
| Mount renders service list | LiveView | Services displayed in sort_order |
| Add service | LiveView | New service appears in list |
| Edit service | LiveView | Updated fields shown |
| Delete service | LiveView | Service removed from list |
| Delete last service blocked | LiveView | Error flash, service remains |
| Move up | LiveView | sort_order swapped, list re-rendered |
| Move down | LiveView | sort_order swapped, list re-rendered |
| Form validation | LiveView | Required field errors shown |

All tests use tenant setup from existing test helpers (ConnCase with authenticated user).
