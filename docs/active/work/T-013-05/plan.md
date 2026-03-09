# T-013-05 Plan: Endorsements CRUD

## Step 1: Add sort_order to Endorsement

### Changes
- Create tenant migration `priv/repo/tenant_migrations/TIMESTAMP_add_endorsement_sort_order.exs`
- Add `sort_order` attribute to `lib/haul/content/endorsement.ex`
- Add `sort_order` to `:add` and `:edit` accept lists
- Run `mix ash.migrate`

### Verify
- `mix compile` succeeds
- Existing endorsement tests pass (`mix test test/haul/content/endorsement_test.exs`)

## Step 2: Add route and sidebar links

### Changes
- Add `live "/content/endorsements", App.EndorsementsLive` to router
- Add Endorsements sidebar link in admin layout (after Services)
- Add Gallery sidebar link in admin layout (after Endorsements)

### Verify
- `mix compile` — will fail until LiveView module exists, that's expected

## Step 3: Implement EndorsementsLive

### Changes
- Create `lib/haul_web/live/app/endorsements_live.ex`
- Full CRUD: mount, add, edit, validate, save, cancel, delete, confirm_delete, move_up, move_down
- Render: header with Add button, inline form, delete confirmation, endorsement list with reorder

### Verify
- `mix compile` succeeds
- Manual review of render output structure

## Step 4: Write tests

### Changes
- Create `test/haul_web/live/app/endorsements_live_test.exs`
- Tests: unauthenticated redirect, mount, render existing, add, edit, validate, delete, reorder, cancel

### Verify
- `mix test test/haul_web/live/app/endorsements_live_test.exs` — all pass
- `mix test` — full suite still passes

## Step 5: Final verification

### Verify
- All tests pass
- No compilation warnings
- Sidebar links render correctly
- CRUD operations work end-to-end
