# T-034-02 Research: setup_all Quick Wins

## Target Files Assessment

### 1. `superadmin_qa_test.exs` — DELETED
The file listed as the biggest win (54→3 schemas, ~15s savings) has been deleted from the repo. It was removed as part of the QA dedup work (visible in git status as `D test/haul_web/live/admin/superadmin_qa_test.exs`). **Not available for conversion.**

### 2. `onboarding_live_test.exs` — 14 tests, ~5s savings
- Path: `test/haul_web/live/app/onboarding_live_test.exs`
- Uses `ConnCase, async: false`
- `setup do` creates authenticated context + provisions tenant + seeds content per test
- Has a second `setup` block inside "public pages after CLI onboarding" describe that runs `Haul.Onboarding.run/1` and mutates `Application.put_env(:haul, :operator, ...)`
- The main describe blocks (authentication, step navigation, steps 1-6) are read-only — they navigate steps and assert HTML. Exception: step 6 "go live" test sets `onboarding_complete = true` via `render_click` on "Launch My Site"
- The "public pages" describe (6 tests) uses its own nested setup — creates a *different* tenant via `Haul.Onboarding.run/1`, sets `:operator` config, and restores in `on_exit`. This is independent of the main tenant.

**Mutation risk:** Step 6 test sets `onboarding_complete = true` on the company. If other tests run after this, they may see the company as already onboarded. Need to either: (a) accept it since no test asserts `onboarding_complete == false`, or (b) move step 6 test last.

**"Public pages" describe:** Cannot share the main setup_all tenant — it creates its own tenant via different mechanism. Must keep its own setup block.

### 3. `page_controller_test.exs` — 8 tests, ~3s savings
- Path: `test/haul_web/controllers/page_controller_test.exs`
- Uses `ConnCase, async: false`
- `setup do` creates company with operator slug, provisions tenant, seeds content, drops all tenant schemas in `on_exit`
- All 8 tests are read-only: GET / and assert HTML content
- Each test receives `conn`, `host`, `tenant` — conn and host can be set up per test from setup_all data
- One test (`page contains services from seeded content`) reads services from DB to build assertions — read-only, no mutation
- **Perfect candidate** — all tests are reads against seeded content

### 4. `impersonation_test.exs` — 16 tests, ~4s savings
- Path: `test/haul_web/live/admin/impersonation_test.exs`
- Uses `ConnCase, async: true` — already async!
- `setup %{conn: conn}` creates admin session + authenticated tenant context per test
- Creates 2 DB records per test: 1 admin user + 1 company+tenant
- Tests: Impersonation helper tests (3, mostly pure function tests), start impersonation (4), exit impersonation (3), privilege stacking (2), tenant user cannot impersonate (1), admin logout (1), impersonation expiry (1), impersonate button (1)

**Complications:**
- Currently `async: true` — converting to setup_all requires `async: false` (since DDL runs outside sandbox). This could **slow down** the suite if impersonation tests currently benefit from concurrent execution.
- Admin session uses `create_admin_session()` which includes Bcrypt hashing (~100ms)
- Tenant context uses `create_authenticated_context()` which provisions schema (~300ms)
- Total per-test: ~400ms × 16 = ~6.4s. With setup_all: ~400ms once = ~5.6s savings. But losing async may cost more.

**Decision needed:** Is losing async: true worth the setup_all savings?

### 5. `accounts_live_test.exs` — 10 tests, ~2s savings
- Path: `test/haul_web/live/admin/accounts_live_test.exs`
- Uses `ConnCase, async: false`
- Uses named setup functions: `setup_admin/1` and `create_companies/1`
- `setup_admin` creates admin via inline code (duplicates factory pattern — uses hardcoded email/password)
- `create_companies` creates 2 companies ("Alpha Hauling", "Beta Junk Removal")
- Only the "accounts list" describe (7 tests) uses both setups
- "accounts list security" describe (3 tests) has no setup — creates its own context inline
- All "accounts list" tests are read-only: render LiveView, search, sort, click rows
- Security tests are independent — one creates `create_authenticated_context()` inline

**Good candidate** — "accounts list" tests are all read-only, but security tests should stay with per-test setup since they don't need admin/companies.

## Existing Infrastructure

### SharedTenant module (`test/support/shared_tenant.ex`)
- Provisions once at suite start, stores context in Application env
- Uses `build_authenticated_context` from Factories
- Designed for `setup_all` usage — provides `get!/0` to retrieve context
- **Not suitable here** — we need per-file setup_all, not global shared tenant. The shared tenant doesn't seed content, doesn't create admin users, and has a fixed name.

### ConnCase sandbox setup
- `setup tags do Haul.DataCase.setup_sandbox(tags)` runs `Sandbox.start_owner!(Repo, shared: not tags[:async])`
- For setup_all files, we need to bypass this — checkout manually in setup_all with `:auto` mode
- The ConnCase `setup` also provides `conn` — we still need per-test `conn` via a `setup` block

### Factories module
- `build_authenticated_context/1` — creates company + tenant + user + token
- `build_admin_session/0` — creates admin with JWT
- `cleanup_all_tenants/0` — drops all tenant schemas except shared-test-co
- These are the right building blocks for setup_all

## Sandbox Mechanics

For `setup_all` with DDL (tenant schema creation):
1. Must manually `Sandbox.checkout(Repo)` in setup_all
2. Must set `Sandbox.mode(Repo, :auto)` so DDL commits outside transaction
3. Individual test `setup` blocks still need sandbox for their own data isolation — but since we're sharing state, we may need `:auto` for the whole module
4. ConnCase's default `setup` calls `setup_sandbox(tags)` which starts a sandbox owner — this would conflict with our setup_all's `:auto` mode
5. **Solution:** We need to skip the ConnCase default sandbox setup when using setup_all. Can do this by setting a tag or by not using `Haul.DataCase.setup_sandbox/1` and instead keeping `:auto` mode throughout.

Since tests sharing setup_all state are all reading the same data, we don't need per-test transaction rollback — we *want* shared state to persist. The setup_all `on_exit` cleans everything up at the end.

## Summary of Viable Conversions

| File | Tests | Viable? | Savings | Notes |
|------|-------|---------|---------|-------|
| superadmin_qa_test.exs | — | DELETED | — | — |
| onboarding_live_test.exs | 14 | Partial | ~5s | Main tests yes, "public pages" block stays as-is |
| page_controller_test.exs | 8 | Full | ~3s | All read-only, perfect candidate |
| impersonation_test.exs | 16 | Risky | ~4s | Currently async:true — losing async may negate gains |
| accounts_live_test.exs | 10 | Partial | ~2s | "accounts list" (7) yes, security (3) stay per-test |

**Revised estimated savings: ~10-14s** (down from ~25-29s due to deleted superadmin_qa_test.exs and impersonation async concern).
