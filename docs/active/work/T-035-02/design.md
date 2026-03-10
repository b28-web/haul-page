# T-035-02 Design: Process-Local Test State

## Problem

Rate limiter uses global ETS keys `{:signup, ip}` / `{:chat, session_id}`. In tests, `clear_rate_limits/0` wipes ALL entries. This forces 5 test files to `async: false`.

## Options evaluated

### Option A: Process-prefixed keys in test mode

Add `self()` or test PID to rate limiter keys when `compile_env(:haul, :env) == :test`:
```elixir
defp rate_key(key), do: if(@test_env, do: {find_test_pid(), key}, else: key)
```

**Pros:** Full isolation per test process. `clear_rate_limits` scoped automatically.
**Cons:** Changes production code path. Must handle `$callers` chain for LiveView processes. Adds complexity to `check_rate/3`. Changes ETS key structure — cleanup `select_delete` match spec must also change.

### Option B: Scoped clear_rate_limits

Keep global keys but make `clear_rate_limits` accept specific keys to delete:
```elixir
def clear_rate_limits(keys) do
  Enum.each(keys, &:ets.delete(@table, &1))
end
```

**Pros:** Minimal change. No production code change.
**Cons:** Tests must know which keys they used. Still global namespace — concurrent tests with same IP could collide. Doesn't truly isolate.

### Option C: Per-process rate limit table (test only)

Create per-process ETS tables in test mode, with a registry.

**Pros:** Complete isolation.
**Cons:** Over-engineered. Multiple ETS tables per test run. Complex lifecycle management.

### Option D: Process-local wrapper with $callers chain

Add a thin wrapper that prefixes keys with the owning test PID, resolved via `$callers`:
```elixir
def check_rate(key, limit, window_seconds) do
  effective_key = if @env == :test, do: {find_owner_pid(), key}, else: key
  # ... existing logic with effective_key
end

defp find_owner_pid do
  callers = Process.get(:"$callers", [])
  List.last(callers) || self()
end
```

**Pros:** Each test's rate limit entries are namespaced by test PID. `clear_rate_limits` can delete only that test's entries. LiveView processes (spawned by test) inherit the test PID via `$callers`. Production code untouched (compile-time branch).
**Cons:** Compile-time env check (already used elsewhere in codebase per T-031).

## Decision: Option D — Process-local wrapper with $callers chain

Rationale:
1. Follows the exact same pattern as ChatSandbox (which is already async-safe)
2. Compile-time env branching is an established pattern in this codebase (7 modules already use it)
3. `$callers` chain handles LiveView → test PID resolution correctly
4. `clear_rate_limits/0` becomes scoped: delete entries matching `{owner_pid, _}` pattern
5. Zero runtime overhead in production (compile-time branch)

## Secondary fix: cleanup_tenants → cleanup_tenant

Files using `cleanup_tenants/0` (global DROP ALL schemas) must switch to `cleanup_tenant/1` (scoped to specific tenant). This helper already exists in ConnCase.

## Async flip candidates

After both fixes:
| File | Can flip? | Notes |
|------|-----------|-------|
| `chat_live_test.exs` | Yes | Rate limiter was only blocker |
| `preview_edit_test.exs` | Yes | Fix rate limiter + tenant cleanup |
| `signup_live_test.exs` | Yes | Fix rate limiter + tenant cleanup |
| `signup_flow_test.exs` | Yes | Fix rate limiter + tenant cleanup |
| `proxy_routes_test.exs` | Partial | Only 1 test uses rate limiter; bigger issue is cleanup_tenants + complex setup |

Target: 4 files flipped to `async: true`, plus proxy_routes if feasible.

## Rejected

- **Option A** — too invasive for production code
- **Option B** — doesn't achieve true isolation
- **Option C** — over-engineered
