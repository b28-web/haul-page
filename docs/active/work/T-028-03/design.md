# T-028-03 Design: Extract LiveView Logic

## Approach

Extract pure functions from LiveView modules into focused helper modules. Group by domain concern, not by source LiveView.

## Module Design

### Option A: Single `HaulWeb.Helpers` module
- Pros: Simple, one import
- Cons: Becomes a grab bag, poor cohesion

### Option B: Domain-grouped modules (chosen)
- Pros: Clear responsibilities, discoverable, testable in isolation
- Cons: More files (but each is small and focused)

### Option C: Per-LiveView helper modules
- Pros: Clear provenance
- Cons: Doesn't solve duplication, just moves it

**Decision: Option B** — Create 4 focused helper modules plus consolidate duplicated patterns.

## Module Plan

### 1. `HaulWeb.Helpers` — Shared view utilities
- `get_field/2` — unified struct/map field accessor (dedup 4 copies)
- `friendly_upload_error/1` — upload error formatting (dedup 3 copies)

### 2. `Haul.Formatting` — Display formatting
- `format_price/1` — cents → "$X/mo" or "Free" (from BillingLive)
- `format_amount/1` — cents → "$X.XX" (from PaymentLive, dedup with BillingLive)
- `plan_name/1` — plan atom → display string
- `plan_rank/1` — plan atom → numeric rank
- `plan_badge_class/1` — plan atom → CSS class
- `star_display/1` — rating → star string
- `source_label/1` — source atom → label
- `days_until_downgrade/1` — DateTime → days remaining

### 3. `Haul.AI.Message` — Chat message manipulation
- `build_transcript/1` — messages → plaintext
- `append_to_last_assistant/2` — append to last assistant msg
- `has_assistant_content?/1` — check last msg
- `deep_to_map/1` — struct tree → plain maps
- `restore_messages/1` — DB messages → runtime structs

### 4. `Haul.Sortable` — Reorder helpers
- `find_swap_index/3` — (items, id, direction) → {idx, swap_idx} | nil
- `next_sort_order/1` — items → next sort_order value

Note: The actual Ash update (swap_sort_order) stays in LiveViews since it requires DB access. Sortable only handles the pure index calculation.

### 5. `Haul.Admin.AccountHelpers` — Admin list operations
- `filter_companies/2` — search by slug/name
- `sort_companies/3` — sort by field + direction
- `toggle_dir/1` — flip sort direction
- `sort_indicator/3` — sort arrow indicator

## What stays in LiveViews
- `handle_event/3` callbacks — thin dispatchers calling extracted functions
- Socket state management (assign, push_event, put_flash)
- `consume_uploaded_entries` — requires socket
- `load_*` functions — DB queries (not pure)
- `assign_*_form` — form state management
- Template rendering (HEEx)
- PubSub subscriptions
- Process monitoring

## Rejected alternatives

### Extract reorder DB updates to Sortable
Rejected: The Ash.update! calls require tenant context and are side effects. Only the pure index calculation belongs in Sortable.

### Create `Haul.Onboarding.Steps` module for step_title
Rejected: step_title is 6 lines, used only in OnboardingLive. Not worth a module. Leave in place.

### Extract BookingLive.merge_preferred_dates to separate module
Accepted: It's a pure param transform, good candidate for HaulWeb.Helpers or a params module. Will add to HaulWeb.Helpers since it's form-related.

## Test Strategy
- Each new module gets `async: true` ExUnit.Case tests
- Pure functions → property-style tests where applicable (e.g. format_amount roundtrip)
- No LiveView mounting needed — that's the whole point
- Existing LiveView tests must pass unchanged (regression check)
