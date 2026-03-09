# T-010-03 Design: Smoke Test

## Decision

Single test file `test/haul_web/smoke_test.exs` with one shared setup block and individual test cases per route. Uses ConnTest for controllers, LiveViewTest for LiveViews.

## Options Considered

### Option A: Parameterized loop over routes
Generate test cases dynamically from a list of `{path, expected_status}` tuples.

**Pros:** DRY, easy to add routes
**Cons:** Mix of controller and LiveView routes need different assertions (`get` vs `live`). Error messages less clear. Over-engineered for 4-5 routes.

**Rejected:** Complexity not justified for the small number of routes.

### Option B: Individual test cases (chosen)
One `describe` block, individual `test` for each route. Shared setup creates company and seeds content.

**Pros:** Clear failure messages, easy to read, follows existing patterns exactly, trivial to add new routes
**Cons:** Slightly more lines than parameterized version

**Chosen:** Simplicity wins. Matches existing test style in the codebase.

### Option C: Separate test files per route type
Split controller routes and LiveView routes into separate test files.

**Rejected:** Defeats the purpose of a single smoke test file that acts as a regression checklist.

## Routes to Test

1. `GET /healthz` → assert 200 (no tenant needed, but harmless to have it)
2. `GET /` → assert 200 (needs tenant + seed)
3. `GET /scan` via `live/2` → assert connected (needs tenant + seed)
4. `GET /book` via `live/2` → assert connected (needs tenant)
5. `GET /scan/qr` → assert 200 (no tenant needed)

## Routes Excluded

- `/pay/:job_id` — requires creating a Job first; this is an integration concern, not smoke
- `/api/places/autocomplete` — API endpoint requiring query params
- `POST /webhooks/stripe` — POST with signature verification, not a page

## Setup Strategy

Single `setup` block:
1. Create Company from operator config
2. Derive tenant schema
3. Seed content (needed for `/` and `/scan`)
4. Cleanup tenant schemas on exit

This matches the pattern in `PageControllerTest` and `BookingLiveTest`.

## Assertions

Keep assertions minimal per the ticket spec:
- Controller routes: `html_response(conn, 200)` or `response(conn, 200)`
- LiveView routes: `{:ok, _view, _html} = live(conn, path)` — successful mount proves no crash
- No DOM assertions beyond what's needed to confirm the page rendered
