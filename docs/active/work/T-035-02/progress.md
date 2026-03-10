# T-035-02 Progress: Process-Local Test State

## Completed

1. **Rate limiter process-local keys** — `lib/haul/rate_limiter.ex` modified. In test mode (`Mix.env() == :test`), `effective_key/1` wraps keys with `hd($callers)` to scope entries per-test process. Zero production overhead (compile-time branch).

2. **Scoped clear_rate_limits** — `test/support/conn_case.ex` modified. Changed from `delete_all_objects` to `match_delete(table, {{self(), :_}, :_})`. Only deletes entries for the calling test process.

3. **chat_live_test.exs** — Flipped to `async: true`. 31 tests pass.

4. **signup_live_test.exs** — Flipped to `async: true`. Fixed pre-existing bug in "shows slug taken" test (was using wrong company name for slug check). Replaced `cleanup_tenants()` with per-test `cleanup_tenant/1`. 11 tests pass.

5. **signup_flow_test.exs** — Already flipped by another agent. Verified passing (14 tests).

6. **preview_edit_test.exs** — Flipped to `async: true`. Replaced global tenant cleanup with scoped `cleanup_tenant("tenant_preview-test-co")`. 22 tests pass.

7. **proxy_routes_test.exs** — Already flipped by another agent (with unique slugs). Verified passing (13 tests).

8. **Documentation** — Added "Process-Local Shared State" section to `docs/knowledge/test-architecture.md`.

## Key learnings

- `Application.compile_env(:haul, :env)` returns nil — there's no `:env` config key. Used `Mix.env()` instead.
- `$callers` chain in LiveView: `[test_pid, module_pid, ...]`. Must use `hd(callers)` (immediate parent = test PID), NOT `List.last(callers)` (root = module PID).
- ChatSandbox was ALREADY async-safe. The blocking factor for chat/preview tests was rate limiter + cleanup_tenants, not ChatSandbox.

## Deviations from plan

- proxy_routes_test.exs and signup_flow_test.exs were already partially flipped by another agent. Verified their correctness.
- Fixed pre-existing bug in signup_live_test.exs slug validation test.
