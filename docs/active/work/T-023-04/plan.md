# T-023-04 Plan: Superadmin Browser QA

## Steps

### Step 1: Create test file with setup

Create `test/haul_web/live/admin/superadmin_qa_test.exs` with:
- Module boilerplate, aliases, imports
- `setup` block: admin, two companies with content, regular user
- Private `create_company_with_content/2` helper
- `on_exit` tenant cleanup

**Verify:** File compiles — `mix test test/haul_web/live/admin/superadmin_qa_test.exs --no-start` (dry run)

### Step 2: Login + dashboard tests

```
describe "superadmin login and dashboard"
  test "admin can access dashboard" — live(admin_conn, "/admin"), assert renders
  test "dashboard shows admin email" — assert html =~ admin.email
```

**Verify:** `mix test test/haul_web/live/admin/superadmin_qa_test.exs`

### Step 3: Accounts list + detail tests

```
describe "accounts list"
  test "shows test companies" — live /admin/accounts, assert both company names

describe "account detail"
  test "shows company info and users" — live /admin/accounts/:slug
  test "impersonate button present" — assert html =~ "Impersonate"
```

**Verify:** run targeted tests

### Step 4: Impersonation flow tests

```
describe "impersonation flow"
  test "start impersonation redirects to /app"
  test "impersonation banner visible with company info"
  test "tenant content matches impersonated company"
  test "exit impersonation returns to admin"
```

For banner test: build conn with pre-set impersonation session keys, mount /app LiveView.

**Verify:** run targeted tests

### Step 5: Security tests

```
describe "privilege stacking blocked"
  test "/admin returns 404 during impersonation"

describe "security: regular user"
  test "regular user gets 404 on /admin"
  test "regular user gets 404 on /admin/accounts/:slug"
  test "unauthenticated gets 404 on /admin"
```

**Verify:** run targeted tests

### Step 6: Full suite verification

Run `mix test` to confirm no regressions.

## Test strategy

- All tests use LiveViewTest + ConnTest (no Playwright)
- Impersonation banner tested by mounting /app with pre-set session keys
- Security tests use `get()` to hit the RequireAdmin plug directly
- Two test companies verify content isolation during impersonation
