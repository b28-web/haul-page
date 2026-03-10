# T-032-01 Structure: Supervised Init Tasks

## Files Modified

### `lib/haul/application.ex`
- Remove lines 27-28 (`Content.Loader.load!()` and `Admin.Bootstrap.ensure_admin!()`)
- Add `Haul.Content.InitTask` and `Haul.Admin.InitTask` to children list, after `Haul.Repo` (needs DB), before `HaulWeb.Endpoint`

### `lib/haul/content/loader.ex`
- Add `loaded?/0` function that checks `:persistent_term.get({__MODULE__, :loaded}, false)`
- Update `load!/0` to set `{__MODULE__, :loaded}` to `true` after successful load

## Files Created

### `lib/haul/content/init_task.ex`
Module: `Haul.Content.InitTask`

```
child_spec/1 — returns %{id: __MODULE__, start: ..., restart: :transient}
run/0 — calls Content.Loader.load!(), logs on failure
```

~15 lines. Thin wrapper providing a named, supervised child spec around `Content.Loader.load!/0`.

### `lib/haul/admin/init_task.ex`
Module: `Haul.Admin.InitTask`

```
child_spec/1 — returns %{id: __MODULE__, start: ..., restart: :transient}
run/0 — calls Admin.Bootstrap.ensure_admin!(), logs on failure
```

~15 lines. Same pattern as Content.InitTask.

### `test/haul/content/init_task_test.exs`
- Test that `Content.Loader.loaded?/0` returns true after InitTask runs
- Test that InitTask can be started as supervised child

### `test/haul/admin/init_task_test.exs`
- Test that InitTask runs without error
- Test that InitTask can be started as supervised child

## Files Not Modified

### `test/test_helper.exs`
No changes needed. Init tasks run during application startup which completes before ExUnit. The tasks are fast (file I/O + JSON parse, DB query) and will complete before any test runs.

### Content-serving routes (PageController, ScanLive, BookingLive)
No 503 gating. These routes use Ash resources via ContentHelpers, not Content.Loader. Adding artificial 503 gates would break working functionality for no benefit.

### `lib/haul/admin/bootstrap.ex`
No changes. Already handles errors gracefully, already idempotent.

## Supervision Tree (after change)

```
Haul.Supervisor (one_for_one)
├── HaulWeb.Telemetry
├── Haul.Repo
├── Oban
├── DNSCluster
├── Phoenix.PubSub
├── Haul.RateLimiter
├── Haul.Content.InitTask    ← NEW (transient)
├── Haul.Admin.InitTask      ← NEW (transient)
└── HaulWeb.Endpoint
```

Init tasks placed after Repo (DB access needed) and before Endpoint (content should be ready before serving). `:transient` restart means they stay down after success, supervisor restarts on crash.

## Module Boundaries

- `Content.InitTask` only calls `Content.Loader.load!/0` — no direct persistent_term access
- `Admin.InitTask` only calls `Admin.Bootstrap.ensure_admin!/0` — no direct DB access
- `Content.Loader.loaded?/0` is the public API for checking content load status
- Existing `Content.Loader.load!/0` remains the implementation — InitTask is just the supervisor integration
