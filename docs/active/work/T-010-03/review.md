# T-010-03 Review: Smoke Test

## Summary

Added `test/haul_web/smoke_test.exs` — a single file that smoke-tests all 5 public routes. Each test asserts the route renders without crashing (200 for controllers, successful mount for LiveViews). No DOM assertions beyond confirming a response.

## Files Changed

| File | Action | Description |
|------|--------|-------------|
| `test/haul_web/smoke_test.exs` | Created | 5 smoke tests for public routes |

## Test Coverage

- **5 new tests** covering `/healthz`, `/`, `/scan`, `/book`, `/scan/qr`
- **Full suite:** 206 tests, 0 failures (up from 201)
- **Execution time:** 1.1 seconds for the smoke test file alone
- **Routes excluded:** `/pay/:job_id` (needs Job creation), `/api/places/autocomplete` (API endpoint), `POST /webhooks/stripe` (requires signature)

## Acceptance Criteria Check

- [x] `mix test test/haul_web/smoke_test.exs` passes
- [x] All public routes return non-500 responses
- [x] Test runs in < 2 seconds (1.1s)
- [x] If a future change breaks a page render, this test fails

## Open Concerns

- **eqrcode deprecation warnings:** The `/scan/qr` test triggers Range deprecation warnings from the `eqrcode` library (v0.1.10). This is a dependency issue, not a test issue. Low priority — the library still works correctly.
- **`/pay/:job_id` not covered:** Would require creating a Job in the setup. Could be added later as part of a payment integration test, but is out of scope for this smoke test.

## Notes

The test follows the exact same tenant setup pattern as `PageControllerTest` and `BookingLiveTest`. The setup creates a company, derives the tenant schema, seeds content, and cleans up schemas on exit. This is the standard pattern across all tenant-aware tests in the project.
