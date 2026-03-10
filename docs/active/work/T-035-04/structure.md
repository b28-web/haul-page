# T-035-04 Structure: LiveView Event Helpers

## Files Created

### `test/support/live_helpers.ex`
Module: `Haul.Test.LiveHelpers`

Public API:
- `build_socket(assigns \\ %{})` — returns `%Phoenix.LiveView.Socket{}`
- `apply_event(module, event, params, socket)` — calls `handle_event/3`
- `apply_info(module, msg, socket)` — calls `handle_info/2`
- `get_assign(result_tuple, key)` — extracts assign from `{:noreply, socket}` or `{:reply, _, socket}`

No dependencies beyond `Phoenix.LiveView.Socket` struct.

### `test/haul_web/live/app/onboarding_live_unit_test.exs`
Module: `HaulWeb.App.OnboardingLiveUnitTest`
Uses: `ExUnit.Case, async: true`
Imports: `Haul.Test.LiveHelpers`

Describe blocks:
- `"next event"` — step increment, clamp at 6
- `"back event"` — step decrement, clamp at 1
- `"goto event"` — valid steps, out-of-range steps, boundary values
- `"validate_logo event"` — no-op returns socket unchanged

Tests: ~10 tests

### `test/haul_web/live/chat_live_unit_test.exs`
Module: `HaulWeb.ChatLiveUnitTest`
Uses: `ExUnit.Case, async: true`
Imports: `Haul.Test.LiveHelpers`

Describe blocks:
- `"update_input event"` — sets :input assign
- `"toggle_profile event"` — flips :show_profile? boolean
- `"go_live event"` — sets :finalized?, appends message, no-op when already finalized
- `"send_message guards"` — empty text, streaming?, finalized? guards
- `"handle_info :ai_chunk"` — appends text to last assistant message
- `"handle_info :provisioning_complete"` — sets provisioning state from result
- `"handle_info :provisioning_failed"` — sets error state
- `"handle_info :DOWN"` — handles task_ref and extraction_ref crashes

Tests: ~15 tests

## Files Modified

### `docs/knowledge/test-architecture.md`
Add a new section after "Tier 1: Unit Tests" documenting the LiveView event helper pattern:
- When to use (pure handle_event/handle_info callbacks)
- When NOT to use (rendering, routing, DB, uploads)
- Example code showing build_socket → apply_event → assert

### `test/test_helper.exs`
No change needed — `test/support/*.ex` files are already compiled via `elixirc_paths` in mix.exs.

## Files NOT Modified

- Existing integration test files — kept intact
- LiveView source modules — no changes needed
- ConnCase — no changes needed
- Factories — no changes needed

## Module Boundaries

```
test/support/live_helpers.ex
  └── Haul.Test.LiveHelpers (4 public functions, no state)

test/haul_web/live/app/onboarding_live_unit_test.exs
  ├── imports Haul.Test.LiveHelpers
  └── calls HaulWeb.App.OnboardingLive.handle_event/3

test/haul_web/live/chat_live_unit_test.exs
  ├── imports Haul.Test.LiveHelpers
  ├── calls HaulWeb.ChatLive.handle_event/3
  └── calls HaulWeb.ChatLive.handle_info/2
```

## Ordering

1. Create `test/support/live_helpers.ex` first (dependency for test files)
2. Create unit test files (can be done in parallel)
3. Update `docs/knowledge/test-architecture.md` (independent)
4. Run `mix test --stale` to verify
