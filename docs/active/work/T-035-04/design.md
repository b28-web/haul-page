# T-035-04 Design: LiveView Event Helpers

## Problem

LiveView tests mount a full GenServer (~30-50ms) even when testing pure handle_event/handle_info logic. We need lightweight helpers to test these callbacks directly.

## Approach Options

### Option A: Minimal Socket Builder + Direct Callback Calls

Create `build_socket/1` that constructs `%Phoenix.LiveView.Socket{}` with given assigns, then call `Module.handle_event/3` directly.

**Pros:** Simple, zero framework coupling beyond struct shape. Tests are fast (<1ms).
**Cons:** Socket struct shape is an internal. push_event/push_navigate won't work naturally. Need to pin to current Phoenix LV version.

### Option B: Phoenix.LiveView.Socket with Component.assign

Same as A but use `Phoenix.Component.assign/3` to build assigns properly (maintains `__changed__` tracking).

**Pros:** Uses official assign API. __changed__ map is correct.
**Cons:** Marginal benefit — __changed__ tracking doesn't matter for unit tests.

### Option C: Test-specific LiveView behaviour module

Define a behaviour that LiveView callbacks implement, test against the behaviour contract.

**Pros:** Clean separation.
**Cons:** Over-engineered. LiveView modules already have `handle_event/3` — we just need to call it.

## Decision: Option A with lightweight assertion helpers

Option A is the right choice. The Socket struct shape has been stable across Phoenix LV versions, and we pin our LV dependency. The helpers should be:

1. **`build_socket/1`** — Creates `%Phoenix.LiveView.Socket{}` with merged assigns. Includes `__changed__: %{}` and `flash: %{}` by default.

2. **`apply_event/4`** — Calls `module.handle_event(event, params, socket)`. Returns the `{:noreply, socket}` or `{:reply, map, socket}` tuple directly. No unwrapping — let the test pattern match.

3. **`apply_info/3`** — Calls `module.handle_info(msg, socket)`. Same return pattern.

4. **`get_assign/2`** — Convenience: `socket.assigns[key]` from a `{:noreply, socket}` tuple. Saves one line of destructuring per assertion.

### Why not unwrap in apply_event/apply_info?

Some callbacks return `{:reply, map, socket}` or modify `socket.redirected`. If we unwrap to just the socket, we lose the ability to assert on these. Returning the raw tuple is more flexible.

## Target LiveViews for Conversion

### Tier 1 (best candidates — pure arithmetic/boolean):
1. **OnboardingLive** — `next`, `back`, `goto` (3 handlers, 4 existing integration tests to supplement)
2. **ChatLive handle_event** — `update_input`, `toggle_profile`, `go_live` (3 handlers)
3. **ChatLive handle_info** — `{:ai_chunk, ...}`, `{:provisioning_complete, ...}`, `{:provisioning_failed, ...}`, `{:DOWN, ...}` (4 handlers)

### Tier 2 (testable but need more setup):
4. **ChatLive send_message guards** — The cond branches before rate limiter check (empty text, streaming?, finalized?) are pure. But testing past the guards requires mocking RateLimiter.
5. **GalleryLive/ServicesLive/EndorsementsLive** — `add`, `edit`, `validate`, `cancel` need pre-built AshPhoenix.Form. More setup, less value.

### Decision: Convert Tier 1 only

The ticket asks for "at least 3 LiveView test files." We'll create unit tests for:
1. `test/haul_web/live/app/onboarding_live_unit_test.exs` — step navigation
2. `test/haul_web/live/chat_live_unit_test.exs` — input/toggle/go_live events + handle_info callbacks

That covers 2 test files with the helpers. For the 3rd, we add unit tests for ChatLive's send_message guard logic (empty, streaming, finalized guards — these are pure checks before the side-effectful code).

We keep existing integration tests intact — they test rendering, routing, auth, and HTML output.

## Helper Module API

```elixir
defmodule Haul.Test.LiveHelpers do
  def build_socket(assigns \\ %{}) do
    %Phoenix.LiveView.Socket{
      assigns: Map.merge(%{__changed__: %{}, flash: %{}}, assigns)
    }
  end

  def apply_event(module, event, params, socket) do
    module.handle_event(event, params, socket)
  end

  def apply_info(module, msg, socket) do
    module.handle_info(msg, socket)
  end

  def get_assign({:noreply, socket}, key), do: socket.assigns[key]
  def get_assign({:reply, _map, socket}, key), do: socket.assigns[key]
end
```

## Rejected Alternatives

- **Mocking Ash/DB for form tests** — violates "Mock the Boundary, Not Ash" convention
- **Extracting callback logic to separate modules** — T-028 already did domain logic extraction. Remaining callbacks are thin wrappers around assign updates — extracting them would create modules with zero reuse.
- **Using ExUnit tag to switch between mount and direct call** — adds complexity for no benefit. Separate test files are clearer.

## Impact on Test Suite

- New unit tests: ~15-20 tests across 2 files
- All `async: true` — run concurrently
- Expected speed: <10ms per test (<1ms each realistically)
- No tests removed — integration tests stay for rendering/routing coverage
- Net result: better coverage of edge cases (step boundary conditions, guard logic) at near-zero cost
