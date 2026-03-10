# T-032-01 Plan: Supervised Init Tasks

## Step 1: Add `loaded?/0` to Content.Loader

**Changes:** `lib/haul/content/loader.ex`
- Add `loaded?/0` function: `:persistent_term.get({__MODULE__, :loaded}, false)`
- Update `load!/0` to set `{__MODULE__, :loaded}` to `true` after storing content data

**Verify:** Run `mix test test/haul/content/loader_test.exs` — existing tests pass

## Step 2: Create Content.InitTask

**Create:** `lib/haul/content/init_task.ex`
- `child_spec/1` returning `%{id: __MODULE__, start: {Task, :start_link, [&run/0]}, restart: :transient}`
- `run/0` calling `Content.Loader.load!()`

**Verify:** Compiles without error

## Step 3: Create Admin.InitTask

**Create:** `lib/haul/admin/init_task.ex`
- Same pattern as Content.InitTask
- `run/0` calling `Admin.Bootstrap.ensure_admin!()`

**Verify:** Compiles without error

## Step 4: Update Application.ex

**Changes:** `lib/haul/application.ex`
- Remove lines 27-28 (synchronous `load!()` and `ensure_admin!()` calls)
- Add `Haul.Content.InitTask` and `Haul.Admin.InitTask` to children list after `Haul.RateLimiter`, before `HaulWeb.Endpoint`

**Verify:** Run `mix test test/haul/content/loader_test.exs test/haul/admin/` — init tasks run via supervision tree now

## Step 5: Write tests

**Create:** `test/haul/content/init_task_test.exs`
- Test `Content.Loader.loaded?/0` returns true (app already started, init task ran)
- Test InitTask child_spec has correct restart strategy

**Create:** `test/haul/admin/init_task_test.exs`
- Test InitTask child_spec has correct restart strategy
- Test that InitTask.run/0 completes without error

**Verify:** Run `mix test test/haul/content/init_task_test.exs test/haul/admin/init_task_test.exs`

## Step 6: Full suite verification

**Run:** `mix test`
- All 845+ tests must pass
- No regressions from moving init tasks into supervision tree

## Testing Strategy

| Test | Tier | What it verifies |
|------|------|-----------------|
| Content.InitTask child_spec | Unit | Correct restart strategy |
| Content.Loader.loaded?/0 | Unit | Flag set after load |
| Admin.InitTask child_spec | Unit | Correct restart strategy |
| Admin.InitTask.run/0 | Unit | Completes without error |
| Full suite regression | Integration | No breakage from supervised init |
