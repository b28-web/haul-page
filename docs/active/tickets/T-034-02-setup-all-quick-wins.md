---
id: T-034-02
story: S-034
title: setup-all-quick-wins
type: task
status: open
priority: high
phase: done
depends_on: []
---

## Context

Several test files create tenant schemas per-test via `setup do` when they could share a single schema via `setup_all`. This is independent of S-033's mock-first approach — it's a mechanical conversion that saves ~25s with minimal risk.

The worst offender is `superadmin_qa_test.exs` which creates 3 schemas per test × 18 tests = 54 schema creates when it only needs 3.

## Target files

| File | Tests | Per-test cost | Schemas/test | Total schemas | Saves |
|------|-------|---------------|-------------|---------------|-------|
| `superadmin_qa_test.exs` | 18 | ~900ms (3 schemas) | 3 | 54 → 3 | ~15s |
| `onboarding_live_test.exs` | 14 | ~400ms (1 schema + seed) | 1 | 14 → 1 | ~5s |
| `page_controller_test.exs` | 8 | ~400ms (1 schema + seed) | 1 | 8 → 1 | ~3s |
| `impersonation_test.exs` | 16 | ~300ms (1 schema) | 1 | 16 → 1 | ~4s |
| `accounts_live_test.exs` | 10 | ~300ms (1 schema) | 1 | 10 → 1 | ~2s |

**Estimated total savings: ~25-29s**

## Acceptance Criteria

- Convert the 5 target files from `setup` to `setup_all` for tenant provisioning
- Each file: create the authenticated context once, share it across all tests
- Use `Ecto.Adapters.SQL.Sandbox.mode(Repo, :auto)` in `setup_all` so DDL persists
- Content seeding (where used) happens once in `setup_all`, not per test
- Mutable per-test state (e.g., conn) still created in `setup` — only the tenant/user context moves to `setup_all`
- `on_exit` in `setup_all` cleans up tenant schemas
- All tests pass across 3 different seeds
- Document the `setup_all` pattern in `docs/knowledge/test-architecture.md` if not already there

## Implementation Notes

- Pattern:
  ```elixir
  setup_all do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Haul.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :auto)

    ctx = build_authenticated_context()
    Haul.Content.Seeder.seed!(ctx.tenant)  # if needed

    on_exit(fn -> cleanup_all_tenants() end)
    %{tenant: ctx.tenant, user: ctx.user, token: ctx.token}
  end

  setup %{token: token} do
    %{conn: build_conn() |> put_req_header("authorization", "Bearer #{token}")}
  end
  ```
- Do NOT convert files that test tenant isolation (`tenant_isolation_test.exs`, `security_test.exs`) — those need per-test schemas by design
- Do NOT convert files where tests mutate shared state in conflicting ways (e.g., one test deletes all services, another asserts service count)
- If any test in a file writes data that another test reads, ensure ordering doesn't matter or use unique identifiers
- `superadmin_qa_test.exs` is the biggest win — 3 schemas created once instead of 54 times

## Risks

- Tests that previously had isolated DB state now share it. Watch for:
  - Count assertions (`assert length(services) == 3`) that break because another test added data
  - Tests that delete records other tests depend on
  - Tests that assert on "the only" record when multiple exist
- Mitigation: use unique identifiers in assertions, assert on specific records not counts
