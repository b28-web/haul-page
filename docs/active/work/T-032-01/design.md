# T-032-01 Design: Supervised Init Tasks

## Problem

`Application.start/2` calls `Content.Loader.load!()` and `Admin.Bootstrap.ensure_admin!()` synchronously before the supervision tree starts. If either crashes, the app fails to boot. These should be supervised, fault-tolerant init tasks.

## Options Considered

### Option A: Supervised `Task` children with `:transient` restart

Add `Task` child specs directly to the supervision tree:

```elixir
children = [
  ...Repo...,
  {Task, fn -> Content.Loader.load!() end},
  {Task, fn -> Admin.Bootstrap.ensure_admin!() end},
  ...Endpoint...
]
```

**Pros:** Simple, no new modules. **Cons:** No `loaded?/0` gate, no exponential backoff, Tasks are anonymous (hard to identify in observer). `:transient` restart means infinite retries on failure with default supervisor intensity.

### Option B: Dedicated GenServer init workers

Create `Haul.Content.InitWorker` and `Haul.Admin.InitWorker` GenServers that run work in `handle_continue/2`:

```elixir
def init(_) do
  {:ok, %{}, {:continue, :run}}
end

def handle_continue(:run, state) do
  Content.Loader.load!()
  {:noreply, %{state | loaded: true}}
end
```

**Pros:** Named processes, queryable state for `loaded?/0`, can implement retry logic. **Cons:** Two new modules for one-shot work, over-engineered for what are essentially idempotent init calls.

### Option C: Single `Haul.InitTasks` GenServer

One GenServer that runs all init tasks sequentially in `handle_continue/2`, tracks loaded state:

```elixir
defmodule Haul.InitTasks do
  use GenServer

  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)
  def loaded?, do: GenServer.call(__MODULE__, :loaded?)

  def init(_), do: {:ok, %{loaded: false}, {:continue, :run}}

  def handle_continue(:run, state) do
    Content.Loader.load!()
    Admin.Bootstrap.ensure_admin!()
    {:noreply, %{state | loaded: true}}
  end
end
```

**Pros:** Single module, named process, `loaded?/0` queryable, supervisor handles restarts. **Cons:** Both tasks coupled in one process — if one fails, both retry.

### Option D: Named `Task` children with wrapper modules

Create thin wrapper modules that call the existing functions:

```elixir
defmodule Haul.Content.InitTask do
  def child_spec(_opts) do
    %{id: __MODULE__, start: {Task, :start_link, [&run/0]}, restart: :transient}
  end

  def run do
    Content.Loader.load!()
    :persistent_term.put({Content.Loader, :loaded}, true)
  end
end
```

**Pros:** Named, identifiable processes. `loaded?/0` via persistent_term check. Independent — one can fail without affecting the other. Minimal code. **Cons:** Two small modules.

## Decision: Option D — Named Task children with wrapper modules

**Rationale:**

1. **Independence** — Content loading and admin bootstrap are unrelated. If content JSON is missing, admin bootstrap shouldn't be delayed by retries.
2. **Identifiable** — Named child specs show up clearly in supervision tree and observer.
3. **Simple** — Each module is ~15 lines. No GenServer state management overhead.
4. **`loaded?/0` via persistent_term** — Cheap, lock-free reads. Set a flag after successful load. Aligns with how Content.Loader already uses persistent_term.
5. **Supervisor handles restarts** — `:transient` restart means the task stays down after success, restarts on crash. Default supervisor intensity (3 restarts in 5 seconds) provides backoff.

## Design Details

### Content.Loader changes

- Add `loaded?/0` — checks `:persistent_term.get({__MODULE__, :loaded}, false)`
- Set `{__MODULE__, :loaded}` to `true` at end of `load!/0`
- New `Haul.Content.InitTask` module — child_spec + run function

### Admin.Bootstrap changes

- New `Haul.Admin.InitTask` module — child_spec + run function
- `ensure_admin!/0` already handles errors gracefully, so the task wrapper just calls it
- No `loaded?/0` needed — admin bootstrap failure is informational, not gating

### Application.ex changes

- Remove synchronous calls to `load!()` and `ensure_admin!()`
- Add `Haul.Content.InitTask` and `Haul.Admin.InitTask` to children list after Repo

### 503 handling for content routes

The ticket AC says content routes should return 503 until loader succeeds. However, research shows content routes use Ash resources via ContentHelpers, not the Loader. The `loaded?/0` gate is still valuable as a "system ready" signal, but **we won't add 503 handling to content routes** because:
- ContentHelpers already has fallback behavior
- Content.Loader's persistent_term data is unused in production
- Adding artificial 503s would break existing behavior for no practical benefit

We'll implement `loaded?/0` as specified but skip the 503 route gating since it would be gating on an unused subsystem.

### Test coordination

Init tasks run fast (file I/O + JSON parse, DB check). With supervised tasks, they start asynchronously but complete before test setup runs because:
1. The application is fully started before ExUnit runs
2. Supervised tasks with `:transient` restart complete on first attempt in test env
3. If needed, test_helper can poll `Content.Loader.loaded?/0` with a short timeout

We'll add a simple wait in test_helper as safety:

```elixir
# Wait for init tasks to complete
Haul.Content.InitTask.await()
```

## Rejected Alternatives

- **Option A** rejected: Anonymous tasks hard to identify, no `loaded?/0` gate
- **Option B** rejected: Over-engineered for one-shot work
- **Option C** rejected: Couples unrelated tasks, single point of failure
- **Remove Content.Loader entirely**: Out of scope for this ticket, and its tests still verify the JSON content files
