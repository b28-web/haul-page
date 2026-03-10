# T-035-02 Research: Process-Local Test State

## Scope

Two shared-state mechanisms force test files to `async: false`:
1. **Rate limiter ETS** — global key space, `clear_rate_limits/0` wipes all entries
2. **ChatSandbox ETS** — already process-local via `$callers`, but test files still `async: false`

## Rate Limiter

### Source: `lib/haul/rate_limiter.ex` (64 lines)

- GenServer creating a `:duplicate_bag` ETS table named `Haul.RateLimiter`
- `check_rate(key, limit, window_seconds)` — inserts `{key, timestamp}`, counts entries in window
- Keys are plain tuples: `{:signup, ip}`, `{:chat, session_id}`
- No process-awareness — all callers share the same key namespace
- Cleanup: `select_delete` for entries older than 1 hour, runs every 60s

### Production callers

| Location | Key | Limit |
|----------|-----|-------|
| `signup_live.ex:174` | `{:signup, ip}` | 5/hour |
| `chat_live.ex:479` | `{:chat, session_id}` | 50/day |

Both callers are LiveView processes (not GenServers), so `self()` is the LiveView PID.

### Test helper: `conn_case.ex:140-144`

```elixir
def clear_rate_limits do
  if :ets.whereis(Haul.RateLimiter) != :undefined do
    :ets.delete_all_objects(Haul.RateLimiter)
  end
end
```

Wipes ALL entries globally. Called in `setup` blocks of 5 test files.

### Test files using `clear_rate_limits/0`

| File | async | Why sync? |
|------|-------|-----------|
| `chat_live_test.exs` | false | `clear_rate_limits` + `ChatSandbox` |
| `preview_edit_test.exs` | false | `clear_rate_limits` + `ChatSandbox` + `cleanup_tenants` |
| `signup_live_test.exs` | false | `clear_rate_limits` + `cleanup_tenants` |
| `signup_flow_test.exs` | false | `clear_rate_limits` + `cleanup_tenants` |
| `proxy_routes_test.exs:155` | false | `clear_rate_limits` (single test) + `cleanup_tenants` |

### Unit tests: `rate_limiter_test.exs`

Already `async: true` — uses `make_ref()` for unique keys per test. No `clear_rate_limits` call.

## ChatSandbox

### Source: `lib/haul/ai/chat/sandbox.ex` (119 lines)

- Named ETS table `Haul.AI.Chat.Sandbox`, `:set`, `:public`
- Keys: `{pid, :response}`, `{pid, :error}` — **already process-scoped**
- `lookup/2` walks `[self() | Process.get(:"$callers", [])]` — LiveView processes find test overrides
- `set_response/1`, `set_error/1` — insert for `self()`
- `clear_response/0`, `clear_error/0` — delete for `self()`
- **Already safe for async: true** — the module docstring says so explicitly

### Why are tests still async: false?

The ChatSandbox is NOT the blocking reason. Tests using ChatSandbox are `async: false` because they ALSO use `clear_rate_limits/0` and/or `cleanup_tenants/0`. Fixing rate limiter isolation is sufficient to unblock async for ChatSandbox test files.

### AI.Sandbox (`lib/haul/ai/sandbox.ex`)

- Uses process dictionary (not ETS) — already per-process
- No cross-process `$callers` lookup (simpler use case)
- Tests using it (`extractor_test.exs`, `content_generator_test.exs`) are already `async: true`

## Other async blockers in target files

| File | Blockers besides rate limiter |
|------|-------------------------------|
| `chat_live_test.exs` | None — ChatSandbox is already async-safe |
| `preview_edit_test.exs` | `cleanup_tenants/0` (global tenant cleanup in on_exit) |
| `signup_live_test.exs` | `cleanup_tenants/0` |
| `signup_flow_test.exs` | `cleanup_tenants/0` |
| `proxy_routes_test.exs` | `cleanup_tenants/0` |

The `cleanup_tenants/0` helper drops ALL `tenant_%` schemas — not async-safe. However, `cleanup_tenant/1` (line 150) exists for scoped cleanup. Files that create known tenants can use `cleanup_tenant(tenant)` instead.

## Key findings

1. **Rate limiter is the primary blocker** — global ETS keys + global wipe
2. **ChatSandbox is already process-local** — not a blocker
3. **cleanup_tenants/0 is a secondary blocker** — must switch to `cleanup_tenant/1`
4. **5 test files** can potentially move to `async: true` if rate limiter + tenant cleanup are fixed
5. Rate limiter is called from LiveView processes, not GenServers — `$callers` chain will work
