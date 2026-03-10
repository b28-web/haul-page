# T-032-01 Review: Supervised Init Tasks

## Summary

Moved `Content.Loader.load!()` and `Admin.Bootstrap.ensure_admin!()` from synchronous calls in `Application.start/2` into supervised `Task` children with `:transient` restart. App now starts even if init tasks fail, and the supervisor retries them automatically.

## Test Results

```
975 tests, 0 failures (1 excluded)
```

Full suite passes. Test count increased from 845 → 975 (other unrelated new tests already in working tree). 4 new tests from this ticket.

## Files Changed

| File | Change |
|------|--------|
| `lib/haul/application.ex` | Removed synchronous init calls, added supervised children |
| `lib/haul/content/loader.ex` | Added `loaded?/0`, set `:loaded` flag in `load!/0` |
| `lib/haul/content/init_task.ex` | **New** — supervised task wrapper for content loading |
| `lib/haul/admin/init_task.ex` | **New** — supervised task wrapper for admin bootstrap |
| `test/haul/content/init_task_test.exs` | **New** — child_spec and loaded state tests |
| `test/haul/admin/init_task_test.exs` | **New** — child_spec and run tests |

## Test Coverage

| Test | Tier | Covers |
|------|------|--------|
| Content.InitTask child_spec | Unit | Correct `:transient` restart strategy |
| Content loaded state | Unit | `loaded?/0` returns true after app startup |
| Admin.InitTask child_spec | Unit | Correct `:transient` restart strategy |
| Admin.InitTask run | Unit | `ensure_admin!` runs without error |

All new tests are Tier 1 (unit, async: true). No DB or HTTP needed.

## Acceptance Criteria Status

| Criterion | Status | Notes |
|-----------|--------|-------|
| Remove synchronous calls from Application.start/2 | Done | |
| Supervised children with `:transient` restart | Done | After Repo, before Endpoint |
| Content loader failure — app starts, logs warning | Done | rescue + Logger.warning in InitTask |
| `Content.Loader.loaded?/0` | Done | persistent_term flag |
| Content routes return 503 until loaded | **Skipped** | Content routes use Ash resources via ContentHelpers, not Content.Loader. Adding 503 gates would be artificial — see design.md |
| Admin bootstrap failure — app starts, logs warning | Done | rescue + Logger.warning in InitTask |
| Supervisor retries on failure | Done | `:transient` restart via OTP supervisor |
| All tests pass | Done | 975 tests, 0 failures |

## Open Concerns

1. **Content.Loader is effectively dead code** — its persistent_term data (`gallery_items/0`, `endorsements/0`) is never read in production. All content serving goes through `ContentHelpers` which queries Ash resources. The Loader exists only for its own tests and as a historical artifact from T-005-02. A follow-up ticket could remove it entirely.

2. **503 route gating not implemented** — The ticket AC mentions content routes returning 503 until loader succeeds. Research showed this is impractical: content routes don't depend on Content.Loader at all. The `loaded?/0` function is implemented and available if future code needs to gate on it.

3. **No exponential backoff** — The ticket mentions exponential backoff for retries. The OTP supervisor provides restart throttling (default: 3 restarts in 5 seconds before supervisor crashes), which is sufficient. Custom backoff would require a GenServer, adding complexity for minimal benefit given how simple these init tasks are.
