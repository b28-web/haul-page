# T-010-03 Progress: Smoke Test

## Completed

- [x] Created `test/haul_web/smoke_test.exs` with 5 test cases
- [x] All 5 smoke tests pass (1.1s)
- [x] Full suite passes: 206 tests, 0 failures (up from 201)
- [x] No deviations from plan

## Routes covered

| Route | Type | Status |
|-------|------|--------|
| GET /healthz | Controller | 200 ✓ |
| GET / | Controller | 200 ✓ |
| GET /scan | LiveView | mount ✓ |
| GET /book | LiveView | mount ✓ |
| GET /scan/qr | Controller | 200 ✓ |
