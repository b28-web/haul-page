# T-014-01 Structure: mix haul.onboard

## New Files

### lib/haul/onboarding.ex — Core onboarding logic
- `Haul.Onboarding`
- Public: `run(params)` where params is `%{name:, phone:, email:, area:}`
- Returns `{:ok, result}` or `{:error, step, reason}`
- Internal steps:
  - `find_or_create_company/1` — slug derivation, uniqueness check, create or return existing
  - `seed_content/1` — calls `Content.Seeder.seed!/2` with default content root
  - `update_site_config/3` — updates SiteConfig with operator phone/email/area
  - `find_or_create_owner/3` — creates User with :owner role in tenant, or finds existing

### lib/mix/tasks/haul/onboard.ex — Mix task wrapper
- `Mix.Tasks.Haul.Onboard`
- `@requirements ["app.start"]`
- `run/1` — parses args, decides interactive vs non-interactive, calls Haul.Onboarding.run/1
- Private: `interactive_prompts/0`, `parse_args/1`, `print_result/1`, `print_error/2`

## Modified Files

### lib/haul/release.ex — Add onboard function
- Add `onboard/1` function that starts app, then calls `Haul.Onboarding.run/1`
- Follows existing `migrate/0` pattern but needs full app start (not just load)

## New Test Files

### test/haul/onboarding_test.exs — Core logic tests
- Test company creation with slug derivation
- Test idempotency (re-run with same slug)
- Test content seeding happens
- Test owner user creation
- Test SiteConfig update with operator details
- Test error handling (invalid email, etc.)

### test/mix/tasks/haul/onboard_test.exs — Mix task CLI tests
- Test non-interactive mode with all flags
- Test missing required flags
- Test task output messages

## Module Boundaries

```
Mix.Tasks.Haul.Onboard (IO layer)
  └── Haul.Onboarding (business logic)
        ├── Haul.Accounts.Company (create_company / read)
        ├── Haul.Accounts.Changes.ProvisionTenant (tenant_schema/1)
        ├── Haul.Content.Seeder (seed!/2)
        ├── Haul.Content.SiteConfig (edit)
        └── Haul.Accounts.User (create with authorize?: false)

Haul.Release.onboard/1 (production entry point)
  └── Haul.Onboarding (same business logic)
```

## Ordering

1. `lib/haul/onboarding.ex` — core module first (no deps on Mix)
2. `test/haul/onboarding_test.exs` — test core logic
3. `lib/mix/tasks/haul/onboard.ex` — thin Mix wrapper
4. `test/mix/tasks/haul/onboard_test.exs` — test CLI interface
5. `lib/haul/release.ex` — add onboard/1
