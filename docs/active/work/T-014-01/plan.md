# T-014-01 Plan: mix haul.onboard

## Step 1: Core Haul.Onboarding module

Create `lib/haul/onboarding.ex` with:
- `run(%{name:, phone:, email:, area:})` — orchestrates the full flow
- `derive_slug/1` — mirrors Company's slug derivation
- `find_or_create_company/2` — reads by slug, creates if missing, updates name if changed
- `seed_content/1` — wraps Content.Seeder.seed!/2
- `update_site_config/3` — reads SiteConfig for tenant, updates phone/email/area
- `find_or_create_owner/3` — reads User by email in tenant, creates with :owner role if missing

Error handling: each step returns {:ok, _} or {:error, reason}. Pipeline short-circuits on first error.

Verify: `mix compile` passes.

## Step 2: Core logic tests

Create `test/haul/onboarding_test.exs`:
- `test "onboards new operator"` — full happy path, verify company, user, content
- `test "idempotent re-run"` — run twice, verify no duplicates
- `test "derives slug from name"` — test slug derivation edge cases
- `test "requires name"` — error on missing name
- `test "requires email"` — error on missing email

Verify: `mix test test/haul/onboarding_test.exs` passes.

## Step 3: Mix task

Create `lib/mix/tasks/haul/onboard.ex`:
- Parse CLI args: `--name`, `--phone`, `--email`, `--area`
- If all provided: non-interactive mode
- If none/partial: interactive mode (prompt for missing)
- Call `Haul.Onboarding.run/1`
- Print result or error
- Exit with appropriate code

Verify: `mix compile` passes.

## Step 4: Mix task tests

Create `test/mix/tasks/haul/onboard_test.exs`:
- Test non-interactive mode with all flags
- Test re-run idempotency via CLI
- Test missing name flag prints error

Verify: `mix test test/mix/tasks/haul/onboard_test.exs` passes.

## Step 5: Release.onboard/1

Add to `lib/haul/release.ex`:
- `onboard(params)` — calls `load_app()`, starts the full app, then `Haul.Onboarding.run(params)`
- Handles the output for production eval context

Verify: `mix compile` passes.

## Step 6: Full test suite

Run `mix test` to ensure no regressions.

## Testing Strategy

- **Unit tests** for Haul.Onboarding: test core logic directly against the database
- **Integration tests** for Mix task: test CLI arg parsing and output formatting
- **No browser tests** for this ticket (CLI-only; T-014-03 covers browser QA)
- All tests use the sandbox with tenant schema provisioning
