# T-022-03 Plan: Proxy Browser QA

## Steps

### Step 1: Create test file with setup

Create `test/haul_web/live/proxy_qa_test.exs` with:
- Module definition, ConnCase, LiveViewTest imports
- Setup block creating two companies via Provisioner (different names, slugs, services)
- on_exit cleanup dropping tenant schemas
- Helper to create company + provision content

### Step 2: Landing page tests

- GET `/proxy/:slug/` → 200, contains business name
- Contains "What We Do" services section
- Links on page use proxy namespace paths

### Step 3: Scan page tests

- `live(conn, "/proxy/:slug/scan")` mounts successfully
- Renders "Scan" content
- "Book Online" link href contains `/proxy/:slug/book`

### Step 4: Booking form tests

- `live(conn, "/proxy/:slug/book")` mounts
- Contains booking form elements
- Form validate event fires without error

### Step 5: Chat tests

- `live(conn, "/proxy/:slug/start")` either mounts chat or redirects
- No crash under proxy context

### Step 6: Cross-tenant tests

- Create second company with different slug/name
- GET `/proxy/slug-a/` shows company A name
- GET `/proxy/slug-b/` shows company B name
- Names don't leak across tenants

### Step 7: LiveView event tests

- Booking form: trigger validate event, confirm no crash
- Scan page: verify interactive elements work

### Step 8: Run tests, fix issues

- `mix test test/haul_web/live/proxy_qa_test.exs`
- Fix any failures
- Run full suite before review

## Testing strategy

- All tests in one file, grouped by `describe` blocks
- Shared setup provisions two tenants
- Each test uses `conn` from setup to hit proxy routes
- Assertions focus on content presence, link correctness, and no crashes
