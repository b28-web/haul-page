# T-010-03 Research: Smoke Test

## Objective

Add a lightweight smoke test that hits every public route and asserts non-500 responses. Prevents future regressions where template assigns, imports, or data dependencies break silently.

## Existing Test Infrastructure

### ConnCase (`test/support/conn_case.ex`)
- `HaulWeb.ConnCase` wraps `ExUnit.CaseTemplate`
- Sets `@endpoint HaulWeb.Endpoint`
- Imports `Plug.Conn`, `Phoenix.ConnTest`
- Calls `Haul.DataCase.setup_sandbox(tags)` in setup hook
- Must use `async: false` for tenant-dependent tests

### DataCase (`test/support/data_case.ex`)
- `Haul.DataCase` provides SQL sandbox setup
- `setup_sandbox/1` starts sandbox owner with `shared: not tags[:async]`

### Test Config (`config/test.exs`)
- Database: `haul_test` with `Ecto.Adapters.SQL.Sandbox`
- Endpoint: port 4002, `server: false`
- All external services sandboxed: Swoosh.Adapters.Test, SMS.Sandbox, Payments.Sandbox, Places.Sandbox
- Oban: `testing: :manual`

## Public Routes (`lib/haul_web/router.ex`)

### Controller routes (no auth)
| Path | Controller | Action |
|------|-----------|--------|
| `/healthz` | HealthController | :index |
| `/` | PageController | :home |
| `/scan/qr` | QRController | :generate |
| `/api/places/autocomplete` | PlacesController | :autocomplete |

### LiveView routes (no auth)
| Path | LiveView |
|------|----------|
| `/scan` | ScanLive |
| `/book` | BookingLive |
| `/pay/:job_id` | PaymentLive |

### Excluded from smoke test
- `POST /webhooks/stripe` — requires Stripe signature, not a page render
- `/api/places/autocomplete` — API endpoint, requires query params
- `/pay/:job_id` — requires a valid job_id, more integration than smoke

## Tenant Setup Pattern

All content-rendering routes require:
1. Create Company via `Ash.Changeset.for_create(:create_company, ...)`
2. Derive tenant: `ProvisionTenant.tenant_schema(company.slug)`
3. Seed content: `Seeder.seed!(tenant)`
4. Cleanup: Drop `tenant_%` schemas in `on_exit`

Routes that need tenant+seed data: `/`, `/scan`, `/book`
Routes that don't: `/healthz`, `/scan/qr`

## Existing Test Patterns

- `PageControllerTest`: Creates company, seeds content, GETs `/`, asserts 200
- `BookingLiveTest`: Creates company, uses `live(conn, "/book")`, asserts HTML
- `HealthControllerTest`: No setup, GETs `/healthz`, asserts 200
- `ScanLiveTest`: Creates company, seeds content, uses `live(conn, "/scan")`

## Key Finding

Most of these routes already have individual tests. The smoke test's value is:
1. Single file that covers ALL public routes — a regression checklist
2. Catches the exact scenario from T-010-01 (missing assigns on mount)
3. Fast: ConnTest only, no browser, should run in < 1s

## Test Count

Current: 201 tests, 0 failures. The smoke test adds ~4-5 new test cases.
