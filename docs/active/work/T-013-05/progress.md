# T-013-05 Progress: Endorsements CRUD

## Completed

### Step 1: Add sort_order to Endorsement ✓
- Created migration `priv/repo/tenant_migrations/20260309040000_add_endorsement_sort_order.exs`
- Added `sort_order` attribute to Endorsement resource
- Added `sort_order` to `:add` and `:edit` accept lists
- Compile + existing tests pass

### Step 2: Route + sidebar links ✓
- Added `live "/content/endorsements", App.EndorsementsLive` to router
- Added Endorsements sidebar link (hero-chat-bubble-left-right icon)
- Added Gallery sidebar link (hero-photo icon, was missing)

### Step 3: EndorsementsLive ✓
- Created `lib/haul_web/live/app/endorsements_live.ex`
- Full CRUD: mount, add, edit, validate, save, cancel, delete, confirm_delete, move_up, move_down
- Inline form with customer_name, quote_text, source select, star_rating, date, featured, active
- List view with reorder arrows, source badges, star display, featured badge
- Delete with PaperTrail version cleanup

### Step 4: Tests ✓
- Created `test/haul_web/live/app/endorsements_live_test.exs`
- 11 tests, all passing
- Coverage: unauthenticated redirect, mount, render existing, add, validate, edit, delete with confirm, delete only endorsement, reorder up/down, cancel

### Step 5: Verification ✓
- `mix compile` — clean, no warnings
- `mix test test/haul_web/live/app/endorsements_live_test.exs` — 11/11 pass
- `mix test` — 304 tests, 1 failure (pre-existing flaky slug test in onboarding_test.exs, unrelated)

## Deviations from Plan
- None
