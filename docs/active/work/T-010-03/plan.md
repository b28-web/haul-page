# T-010-03 Plan: Smoke Test

## Steps

### Step 1: Create the smoke test file

Create `test/haul_web/smoke_test.exs` with:
- Module declaration, ConnCase usage, LiveViewTest import
- Aliases for Company, ProvisionTenant, Seeder
- Setup block: create company, derive tenant, seed content, cleanup on exit
- Five test cases covering all public routes

### Step 2: Run the test file in isolation

```
mix test test/haul_web/smoke_test.exs
```

Verify:
- All 5 tests pass
- No warnings or compilation errors
- Runs in < 2 seconds

### Step 3: Run the full test suite

```
mix test
```

Verify:
- All existing tests still pass (no regressions)
- New tests integrate cleanly
- No sandbox or tenant isolation issues

### Step 4: Commit

Single atomic commit with the new test file.

## Testing Strategy

- **What gets tested:** Every public route renders without crashing
- **Verification criteria:** 200 status for controllers, successful LiveView mount for LiveViews
- **No DOM assertions:** This is explicitly a smoke test, not a feature test
- **Speed target:** < 2 seconds total for the file
