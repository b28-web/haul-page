---
id: T-035-04
story: S-035
title: liveview-event-helpers
type: task
status: open
priority: medium
phase: done
depends_on: []
---

## Context

LiveView tests use `Phoenix.LiveViewTest` which mounts a full GenServer, processes through the router + plugs + tenant resolution, and renders HTML. Each mount costs ~30-50ms. This is appropriate for testing user flows but overkill for testing event handling logic.

Many LiveView `handle_event/3` and `handle_info/2` callbacks are essentially pure functions: they take a socket, do some computation on assigns, and return an updated socket. Testing these through full mount wastes 30-50ms per test on infrastructure that isn't being tested.

This ticket creates lightweight helpers to test LiveView event logic without mounting.

## Acceptance Criteria

- Create `test/support/live_helpers.ex` with:
  - `build_socket/1` — creates a minimal `%Phoenix.LiveView.Socket{}` with given assigns
  - `apply_event/3` — calls a LiveView's `handle_event/3` directly with the socket
  - `apply_info/2` — calls a LiveView's `handle_info/2` directly with the socket
  - `get_assign/2` — extracts an assign from the returned socket tuple
- Convert at least 3 LiveView test files to use event helpers for logic-only tests, keeping 1-2 full mount tests per file for integration coverage
- Event helper tests should be `ExUnit.Case, async: true` and sub-10ms each
- Document the pattern in `docs/knowledge/test-architecture.md` with examples

## Implementation Notes

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
end
```

### Good candidates for conversion

- **ChatLive** `handle_event("send", ...)` — message list manipulation is pure
- **BookingLive** `handle_event("validate", ...)` — changeset validation logic
- **GalleryLive/ServicesLive/EndorsementsLive** `handle_event("reorder", ...)` — already extracted to `Haul.Sortable`, but the handle_event wrapper itself could be tested this way
- **OnboardingLive** step navigation logic — `handle_event("next-step", ...)` updates assigns

### What to keep as full mount tests

- Tests that assert on rendered HTML (`assert html =~ "..."`)
- Tests that verify navigation (`assert_redirect`, `assert_patch`)
- Tests that exercise the full plug pipeline (tenant resolution, auth)
- Tests where `mount/3` itself is the thing being tested

## Risks

- `build_socket/1` won't have all the assigns that `mount/3` would set up. Tests need to provide the relevant assigns explicitly — this can be brittle if mount logic changes
- Some `handle_event` callbacks use `socket.assigns` fields that are complex (changesets, streams). Building realistic socket state may be as much work as mounting
- LiveView internals: if Phoenix changes the `Socket` struct in a future version, `build_socket/1` may break. Pin to the current struct shape and update on upgrade
- Don't over-apply this — it's best for callbacks with clear input→output logic, not for callbacks that heavily interact with PubSub or redirect
