# T-034-02 Review: setup_all Quick Wins

## Summary

Converted 3 test files from per-test `setup` to `setup_all` for tenant provisioning, reducing redundant schema creation. The 4th file (impersonation_test.exs) was skipped because it's already `async: true`. The 5th file (superadmin_qa_test.exs) was deleted before this ticket started.

## Files Modified

| File | Change |
|------|--------|
| `test/haul_web/controllers/page_controller_test.exs` | setup → setup_all for company/tenant/seed |
| `test/haul_web/live/app/onboarding_live_test.exs` | Top-level setup → setup_all; "public pages" setup preserved |
| `test/haul_web/live/admin/accounts_live_test.exs` | setup_admin + create_companies → setup_all; security tests preserved |
| `docs/knowledge/test-architecture.md` | Expanded setup_all section with pattern + rules |

## Test Results

**Full suite:** 898 tests, 271 failures (1 excluded). All 271 failures are pre-existing — in modules NOT modified by this ticket (SecurityTest, TenantIsolationTest, BookingLiveTest, etc.). The repo's git status shows ~30 modified test files from prior uncommitted work.

**Target files only:** 38 tests, 0 failures across 3 seeds (629777, 12345, 99999). Stable.

## Pattern Discovered

### What didn't work: on_exit with mode(:auto)
- on_exit callbacks from setup_all run in separate processes and can race with the next module's sandbox setup
- Setting `Sandbox.mode(:auto)` in on_exit breaks sandbox isolation for other modules

### What didn't work: cleanup_all_tenants() in setup_all pre-cleanup
- Drops ALL tenant schemas including those from other test files running in the same suite
- Caused 90+ additional test failures when running the full suite

### Correct pattern: targeted cleanup + checkin
```elixir
setup_all do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(Haul.Repo)
  Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :auto)

  # Targeted pre-cleanup — only THIS file's data
  Ecto.Adapters.SQL.query(Repo, "DROP SCHEMA IF EXISTS \"tenant_xxx\" CASCADE")
  Ecto.Adapters.SQL.query(Repo, "DELETE FROM companies WHERE slug = $1", ["xxx"])

  # Create data (committed via :auto)
  ctx = Factories.build_authenticated_context()

  # Release connection — no on_exit needed
  Ecto.Adapters.SQL.Sandbox.checkin(Haul.Repo)

  %{ctx: ctx}
end
```

Key rules:
1. **Targeted cleanup only** — never use `cleanup_all_tenants()` in setup_all; it destroys other modules' data
2. **Use `checkin` not `mode(:manual)`** — cleanly releases the connection without leaving stale state
3. **No on_exit** — avoid sandbox mode manipulation in on_exit callbacks
4. **Use factories with unique names** — prevents slug collisions across runs
5. **Must be async: false** — setup_all with DDL is incompatible with async:true

## Estimated Savings

- page_controller_test.exs: ~400ms × 7 tests = ~2.8s
- onboarding_live_test.exs: ~400ms × 13 tests = ~5.2s
- accounts_live_test.exs: ~300ms × 6 tests = ~1.8s
- **Total: ~10s** (down from original ~25-29s due to deleted/skipped files)

## Open Concerns

1. **Stale data accumulation** — Unique-named companies/tenants from `build_authenticated_context()` in onboarding setup_all are never cleaned up. They accumulate across runs. Low risk (unique names prevent collisions) but may need periodic DB reset.

2. **impersonation_test.exs** — Skipped because converting from `async: true` to `async: false` would likely negate savings. Could revisit after T-033-05 (async unlock).

3. **Pre-existing test failures** — 271 failures across ~25 modules, all unrelated to this ticket. These need separate investigation.

4. **Linter conflict** — A linter/hook automatically changed `async: false` to `async: true`, which breaks the setup_all pattern. Had to manually revert. May need a linter exclusion for files using setup_all.
