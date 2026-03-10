# T-035-04 Research: LiveView Event Helpers

## Current State

All LiveView tests use `HaulWeb.ConnCase` + `Phoenix.LiveViewTest`. Every test mounts via `live(conn, path)` which:
1. Routes through the plug pipeline (Endpoint → Router → Plugs)
2. Resolves tenant (TenantResolver plug or session-based)
3. Calls `mount/3` on the LiveView module
4. Renders initial HTML
5. Establishes a GenServer process

This costs ~30-50ms per mount. For tests that only verify event handling logic (not rendering or routing), this overhead is unnecessary.

## Socket Struct Shape

`Phoenix.LiveView.Socket` (from deps):
```elixir
defstruct id: nil, endpoint: nil, view: nil, parent_pid: nil, root_pid: nil,
          router: nil, assigns: %{__changed__: %{}},
          private: %{live_temp: %{}}, redirected: nil, host_uri: nil,
          transport_pid: nil, sticky?: false
```

Key: `assigns` defaults to `%{__changed__: %{}}`. The `assign/3` function from `Phoenix.Component` updates both the value and `__changed__` map. The `flash` assign is set during mount by the framework.

## Pure Callback Candidates

### OnboardingLive (best candidate — 3 pure handlers)
- `"next"` — `min(step + 1, 6)` → assign :step. Pure arithmetic.
- `"back"` — `max(step - 1, 1)` → assign :step. Pure arithmetic.
- `"goto"` — `String.to_integer(step)`, validate in `@steps (1..6)`, assign :step.
- `"validate_info"` — `AshPhoenix.Form.validate` (in-memory). But requires a real AshPhoenix.Form struct in assigns — building one without DB is possible but fragile.
- `"validate_logo"` — no-op, returns `{:noreply, socket}`.

Current tests: 4 tests in "step navigation" describe block, all use full mount. Async: false, setup_all pattern.

### ChatLive (3 pure handlers + several pure handle_info)
**handle_event:**
- `"update_input"` — assigns :input to text. Trivially pure.
- `"toggle_profile"` — toggles :show_profile? boolean. Pure.
- `"go_live"` — guards on finalized?, appends message to list, assigns :finalized?. Uses `push_event` (adds to socket.private — harmless in unit test).

**handle_info (pure subset):**
- `{:ai_chunk, text}` — `AIMessage.append_to_last_assistant` (pure list op) + assign + push_event. Pure if we don't assert on push_event.
- `{:provisioning_complete, result}` — assigns from result map, appends message. Pure.
- `{:provisioning_failed, _}` — assigns + appends error message. Pure.
- `{:ai_error, reason}` — assigns + flash. Uses `redirect` for first-message case (side effect) but second branch is pure.
- `{:DOWN, ref, ...}` — pattern matches on task_ref/extraction_ref, updates assigns.

Current tests: 7+ describe blocks, all ConnCase async: true. Heavy use of ChatSandbox.

### BookingLive (2 pure handlers)
- `"validate"` — `AshPhoenix.Form.validate` on ash_form. Same fragility as OnboardingLive.
- `"cancel-upload"` — `cancel_upload(socket, :photos, ref)`. Requires upload state in socket — framework-managed, hard to fake.
- `"reset"` — assigns :submitted false + calls `assign_form/1` which creates a new AshPhoenix.Form (needs tenant in assigns + Ash resource module). Actually touches Ash metadata at form creation time.

Current tests: ConnCase async: true. Separate test files for autocomplete + upload.

### GalleryLive / ServicesLive / EndorsementsLive
- `"add"`, `"edit"`, `"validate"`, `"cancel"` — form management, mostly pure
- `"move_up"`, `"move_down"` — NOT pure, call Ash.update!
- `"save"`, `"delete"`, `"confirm_delete"` — DB writes

The "pure" handlers here all involve AshPhoenix.Form construction or item lookup from assigns. Testable with pre-built assigns, but the form construction requires understanding Ash internals.

## AshPhoenix.Form Consideration

`AshPhoenix.Form.validate/2` is in-memory — it validates params against the form's changeset without touching the DB. However, constructing an AshPhoenix.Form with `for_create/3` or `for_update/3` reads resource metadata at call time. If we pre-build the form in test setup, validate is pure. But this means:
1. We need a DB-created resource for `for_update` forms
2. Or we use `for_create` which only needs the resource module + action name

For unit testing, we can only test validate if we provide a pre-built form. This limits the value — the form is the complex part.

## What Doesn't Work for Unit Testing

1. **Upload-related handlers** — `cancel_upload/3` and `consume_uploaded_entries/3` expect framework-managed upload state in `socket.private`.
2. **AshPhoenix.Form creation** — needs resource metadata, sometimes tenant context.
3. **Handlers with push_event/push_navigate/redirect** — these modify `socket.redirected` or `socket.private`. Harmless but can't be asserted on without framework helpers.
4. **Handlers calling Ash.update!/Ash.create!** — DB operations, by definition not pure.

## What Works Well for Unit Testing

1. **OnboardingLive step navigation** — `next`, `back`, `goto` are pure arithmetic on a single integer assign. Zero framework dependencies beyond `Phoenix.Component.assign/3`.
2. **ChatLive toggle/input** — `update_input`, `toggle_profile` are trivial assign updates.
3. **ChatLive go_live** — list append + boolean assign. Uses `push_event` but that just adds to private state.
4. **ChatLive handle_info callbacks** — `{:ai_chunk, text}`, `{:provisioning_complete, ...}`, `{:provisioning_failed, ...}`, `{:DOWN, ...}` are pure assign manipulations.

## Existing Test Infrastructure

- `test/support/conn_case.ex` — ConnCase with auth helpers
- `test/support/factories.ex` — build_company, provision_tenant, etc.
- No `test/support/live_helpers.ex` exists yet
- `test/test_helper.exs` — ExUnit config
- All LiveView tests currently use ConnCase (Tier 3)

## File Counts

- 23 LiveView test files under `test/haul_web/live/`
- ~50+ handle_event callbacks across all LiveViews
- ~15 handle_info callbacks (mostly in ChatLive)
- Of these, ~20 are pure enough for unit testing
