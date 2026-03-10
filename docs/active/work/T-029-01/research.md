# T-029-01 Research — Document Test Tiers

## Current State

The codebase has 845 tests across three implicit tiers, but no documentation defining which tier to use when. New tests default to integration because that's what most existing tests demonstrate.

## Tier 1: Unit Tests (Pure Functions)

**Test case base:** `ExUnit.Case, async: true`
**DB access:** No | **HTTP:** No | **Speed:** <100ms

Examples found in codebase:
- `test/haul/formatting_test.exs` — `plan_rank/1`, `format_price/1`, etc.
- `test/haul/sortable_test.exs` — `find_swap_index/3`, `next_sort_order/1`
- `test/haul/billing_test.exs` — `can?/2`, `plan_features/1`, `plans/0`
- `test/haul/ai/message_test.exs` — `build_transcript/1`, `deep_to_map/1`
- `test/haul/ai/error_classifier_test.exs` — `transient?/1`

Pattern: No setup block, inline test data, `async: true`. Tests pure functions with no side effects.

## Tier 2: Resource Tests (Ash + DB)

**Test case base:** `Haul.DataCase, async: false`
**DB access:** Yes | **HTTP:** No | **Speed:** 100ms–1s

Examples found:
- `test/haul/content/service_test.exs` — Ash CRUD on Service resource
- `test/haul/content/page_test.exs` — Page create/edit with markdown rendering
- `test/haul/accounts/user_test.exs` — registration, sign-in validation
- `test/haul/ai/provisioner_test.exs` — Provisioner creates resources
- `test/haul/tenant_isolation_test.exs` — cross-tenant access denied

Pattern: `setup` creates company + provisions tenant, `on_exit` drops schema. All use `authorize?: false` for test data creation. Tests Ash actions, validations, relationships, policies.

## Tier 3: Integration Tests (HTTP/LiveView)

**Test case base:** `HaulWeb.ConnCase, async: false`
**DB access:** Yes | **HTTP:** Yes | **Speed:** 500ms–3s

Examples found:
- `test/haul_web/controllers/page_controller_test.exs` — GET /, content assertions
- `test/haul_web/live/app/billing_live_test.exs` — LiveView mount + events
- `test/haul_web/live/booking_live_test.exs` — form rendering + validation
- `test/haul_web/smoke_test.exs` — all public routes render without crash

Pattern: ConnCase helpers for auth context + login. LiveView tests use `live/2`, `render_click/3`. Full request/response cycle.

## Test Infrastructure

| File | Purpose |
|------|---------|
| `test/test_helper.exs` | Sandbox `:manual` mode, optional timing formatter |
| `test/support/data_case.ex` | Ecto sandbox setup, changeset helpers |
| `test/support/conn_case.ex` | HTTP + DataCase combined, auth helpers |
| `test/support/factories.ex` | `build_company/1`, `build_user/2`, resource factories |
| `test/support/shared_tenant.ex` | Shared tenant (exists, not yet activated) |
| `test/support/timing_formatter.ex` | Per-test timing profiler (`HAUL_TEST_TIMING=1`) |

## Factory Pattern

All factories in `test/support/factories.ex`:
- Account-level: `build_company/1`, `provision_tenant/1`, `build_user/2`, `build_authenticated_context/1`
- Resource-level: `build_service/2`, `build_page/2`, `build_booking_job/2` — all take `(tenant, attrs \\ %{})`
- All use `authorize?: false` to bypass policies during setup

## Async Behavior

- Tier 1: `async: true` — concurrent, no shared state
- Tier 2 & 3: `async: false` — serial, per-test tenant schemas, sandbox isolation
- Sandbox mode: `:manual` (each test starts its own owner via `DataCase.setup_sandbox/1`)

## Files to Modify

1. **Create:** `docs/knowledge/test-architecture.md` — full documentation
2. **Edit:** `CLAUDE.md` § Test Targeting — add tier definitions + rule
3. **Edit:** `.just/system.just` `_llm` recipe — add test tier summary
4. **Edit:** `docs/knowledge/rdspi-workflow.md` — add review checklist item

## Constraints

- Documentation-only ticket: no test code changes
- Must use concrete examples from the codebase
- Decision tree must be simple and actionable
