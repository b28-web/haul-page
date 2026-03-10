# T-035-02 Structure: Process-Local Test State

## Files modified

### 1. `lib/haul/rate_limiter.ex`

Add process-local key wrapping in test mode:

```
check_rate/3:
  - In test: wrap key as {owner_pid, original_key}
  - In prod: use original_key unchanged (compile-time branch)

New private functions:
  - effective_key/1 — wraps key with owner PID in test mode
  - find_owner_pid/0 — walks $callers to find root test PID

Cleanup select_delete match spec:
  - Must handle both {key, timestamp} and {{pid, key}, timestamp} shapes
  - Only relevant in test; production keys are never prefixed
```

### 2. `test/support/conn_case.ex`

Modify `clear_rate_limits/0`:
```
Before: :ets.delete_all_objects(Haul.RateLimiter)
After:  :ets.match_delete(Haul.RateLimiter, {{owner_pid, :_}, :_})
        where owner_pid = self()
```

Only deletes entries belonging to the calling test process.

### 3. `test/haul_web/live/chat_live_test.exs`

- Change `async: false` → `async: true`
- Keep `clear_rate_limits()` in setup (now scoped)
- Keep ChatSandbox clear calls (already process-safe)

### 4. `test/haul_web/live/preview_edit_test.exs`

- Change `async: false` → `async: true`
- Replace `cleanup_tenants` in on_exit with scoped `cleanup_tenant(tenant)` for each created tenant
- Keep rate limiter and ChatSandbox setup calls

### 5. `test/haul_web/live/app/signup_live_test.exs`

- Change `async: false` → `async: true`
- Replace `cleanup_tenants()` with scoped `cleanup_tenant/1`

### 6. `test/haul_web/live/app/signup_flow_test.exs`

- Change `async: false` → `async: true`
- Replace `cleanup_tenants()` with scoped `cleanup_tenant/1`

### 7. `test/haul_web/plugs/proxy_routes_test.exs`

- Evaluate for `async: true` — uses `cleanup_tenants` and creates multiple companies
- Replace `cleanup_tenants` with per-tenant cleanup if feasible
- Single `clear_rate_limits` call at line 155

### 8. `docs/knowledge/test-architecture.md`

Add section documenting:
- Process-local rate limiter pattern
- ChatSandbox $callers pattern (already exists, document)
- How to make new shared state async-safe

## Files NOT modified

- `lib/haul/ai/chat/sandbox.ex` — already async-safe, no changes needed
- `lib/haul/ai/sandbox.ex` — already per-process via process dictionary
- `test/haul/rate_limiter_test.exs` — already async: true via make_ref keys

## Module boundaries

- `Haul.RateLimiter` — sole owner of rate limiting logic. Test-mode key wrapping is internal.
- `HaulWeb.ConnCase` — sole owner of `clear_rate_limits/0` helper. Tests don't touch ETS directly.
- Test files — only change async flag and tenant cleanup strategy.

## Ordering

1. Rate limiter changes (key wrapping + clear_rate_limits scoping)
2. Test file async flips (one at a time, verify each)
3. Documentation update
