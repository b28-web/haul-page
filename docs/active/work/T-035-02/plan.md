# T-035-02 Plan: Process-Local Test State

## Step 1: Make rate limiter keys process-local in test mode

**File:** `lib/haul/rate_limiter.ex`

- Add `@env Application.compile_env(:haul, :env)`
- Add `effective_key/1` that wraps key with `find_owner_pid()` when `@env == :test`
- Add `find_owner_pid/0` that returns `List.last(Process.get(:"$callers", [])) || self()`
- Modify `check_rate/3` to use `effective_key(key)` instead of raw `key`
- Verify: `mix test test/haul/rate_limiter_test.exs` still passes

## Step 2: Scope clear_rate_limits to calling process

**File:** `test/support/conn_case.ex`

- Change `clear_rate_limits/0` from `delete_all_objects` to `match_delete` using `{self(), :_}` pattern
- Pattern: `:ets.match_delete(@table, {{self(), :_}, :_})`
- Verify: `mix test --stale` passes

## Step 3: Flip chat_live_test.exs to async: true

**File:** `test/haul_web/live/chat_live_test.exs`

- Change `use HaulWeb.ConnCase, async: false` → `async: true`
- No other changes needed (ChatSandbox already async-safe, rate limiter now scoped)
- Verify: `mix test test/haul_web/live/chat_live_test.exs` passes
- Run 3x with different seeds to check for flakiness

## Step 4: Flip signup_live_test.exs to async: true

**File:** `test/haul_web/live/app/signup_live_test.exs`

- Change `async: false` → `async: true`
- Replace `cleanup_tenants()` with scoped `cleanup_tenant/1` — need to track created tenant slugs
- Verify: `mix test test/haul_web/live/app/signup_live_test.exs`

## Step 5: Flip signup_flow_test.exs to async: true

**File:** `test/haul_web/live/app/signup_flow_test.exs`

- Change `async: false` → `async: true`
- Replace `cleanup_tenants()` with scoped cleanup
- Verify: `mix test test/haul_web/live/app/signup_flow_test.exs`

## Step 6: Flip preview_edit_test.exs to async: true

**File:** `test/haul_web/live/preview_edit_test.exs`

- Change `async: false` → `async: true`
- Replace global tenant cleanup in on_exit with scoped cleanup
- Verify: `mix test test/haul_web/live/preview_edit_test.exs`

## Step 7: Evaluate proxy_routes_test.exs

**File:** `test/haul_web/plugs/proxy_routes_test.exs`

- Read full file to assess complexity
- If feasible, flip to `async: true` + scoped cleanup
- If not (complex multi-tenant setup), document why and leave as async: false

## Step 8: Full suite verification

- Run `mix test` 3 times with different seeds
- Verify no new failures

## Step 9: Document patterns

**File:** `docs/knowledge/test-architecture.md`

- Add "Process-Local Shared State" section
- Document rate limiter pattern (compile-time key wrapping + $callers)
- Document ChatSandbox pattern (already async-safe)
- Add guidance for making new shared state async-safe

## Testing strategy

- **Per-step:** `mix test --stale` after each change
- **Per-flip:** Run the specific test file 3x with `--seed 0`, `--seed 12345`, `--seed 99999`
- **Final:** `mix test` full suite, note result in review
