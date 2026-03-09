# T-014-03 Plan: Browser QA for CLI Onboarding

## Step 1: Create Test File

Create `test/haul_web/live/onboarding_qa_test.exs` with:

### Setup
```elixir
setup do
  # Save original operator config
  original = Application.get_env(:haul, :operator)

  # Run onboarding
  params = %{name: "Test Hauling", phone: "555-0199", email: "test@example.com", area: "Portland, OR"}
  {:ok, result} = Haul.Onboarding.run(params)

  # Override operator config so ContentHelpers.resolve_tenant() finds our tenant
  Application.put_env(:haul, :operator, Keyword.merge(original || [], slug: result.company.slug))

  on_exit(fn ->
    Application.put_env(:haul, :operator, original)
    cleanup_tenants()
  end)

  %{result: result}
end
```

### Test: Landing page content
- GET `/` → html_response(200)
- Assert contains "Test Hauling" (business name from SiteConfig)
- Assert contains "555-0199" (phone)
- Assert contains "test@example.com" (email)
- Assert contains "Portland, OR" (service area)
- Assert contains "What We Do" (services section heading)
- Assert contains service titles from defaults (e.g., "Junk Removal")

### Test: Scan page content
- live `/scan` → assert gallery section "Our Work"
- Assert endorsements section "What Customers Say"
- Assert business name appears
- Assert phone appears
- Assert gallery items present (before/after captions)
- Assert endorsement quotes present

### Test: Booking form
- live `/book` → assert form renders
- Assert contains booking-related elements

### Test: Admin login page
- live `/app/login` → assert "Sign In" heading
- Assert email and password fields present

### Test: Content quality
- Verify services have real titles (not placeholder text)
- Verify endorsements exist with customer names containing "(Sample)"
- Verify gallery items have captions

## Step 2: Run Tests

Run `mix test test/haul_web/live/onboarding_qa_test.exs` and fix any failures.

## Step 3: Run Full Suite

Run `mix test` to ensure no regressions.

## Verification Criteria

- All new tests pass
- Full test suite passes with 0 failures
- Tests verify all acceptance criteria from ticket
