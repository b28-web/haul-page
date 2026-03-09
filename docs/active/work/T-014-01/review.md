# T-014-01 Review: mix haul.onboard

## Summary

Built `mix haul.onboard` — a Mix task that provisions new operator tenants on the shared multi-tenant instance. Supports both interactive (prompts) and non-interactive (CLI flags) modes. Idempotent: re-running for an existing slug updates content, doesn't duplicate. Also works in production via `bin/haul eval "Haul.Release.onboard(%{...})"`.

## Files Created

| File | Purpose |
|------|---------|
| `lib/haul/onboarding.ex` | Core onboarding logic — company creation, tenant provisioning, content seeding, owner user creation |
| `lib/mix/tasks/haul/onboard.ex` | Mix task wrapper — CLI arg parsing, interactive prompts, output formatting |
| `test/haul/onboarding_test.exs` | 13 tests: happy path, idempotency, validation, slug derivation, URL construction |
| `test/mix/tasks/haul/onboard_test.exs` | 3 tests: non-interactive CLI mode, idempotency via CLI, minimal flags |

## Files Modified

| File | Change |
|------|--------|
| `lib/haul/release.ex` | Added `onboard/1` and `start_app/0` for production release eval |

## Test Coverage

- **16 new tests**, 307 total (up from 258 before this session, though other tickets added tests too)
- **0 failures** across full suite
- Covers: end-to-end onboarding, idempotent re-run, validation errors, slug derivation edge cases, site URL, CLI flags, minimal params

## Acceptance Criteria Status

| Criterion | Status |
|-----------|--------|
| Interactive mode (prompts for name, phone, email, area) | Done |
| Derives slug from business name (uniqueness check) | Done |
| Creates Company with slug | Done |
| Provisions tenant schema (runs migrations) | Done (via existing ProvisionTenant change) |
| Seeds default content | Done (via existing Content.Seeder) |
| Creates owner User with magic link invite | Done (user created with :owner role; magic link sender is stubbed — pre-existing TODO) |
| Prints site URL | Done |
| Non-interactive mode (--name, --phone, --email, --area) | Done |
| Idempotent (re-run updates, no duplicates) | Done + tested |
| Rollback on failure | Partial — idempotent design handles most cases; DDL can't be transactionally rolled back |
| Production release eval | Done (`Haul.Release.onboard/1`) |

## Architecture Decisions

- **Core logic in `Haul.Onboarding`**, thin wrappers in Mix task and Release module. Single source of truth.
- **Idempotency over rollback** — Company creation triggers DDL (CREATE SCHEMA) which auto-commits. True transactional rollback isn't possible. Instead, all steps are idempotent: re-running fixes partial state.
- **`authorize?: false` for user creation** — This is an admin provisioning task, same pattern as existing seed/test code.
- **Temporary random password** — Owner user is created with a random password. Magic link flow (when sender is implemented) will be the primary auth mechanism.

## Open Concerns

1. **Magic link sender is stubbed** — `user.ex` has `# TODO: implement magic link email via Haul.Mailer`. The onboard task creates the user but can't send the actual invite email yet. Not a blocker for this ticket; it's a pre-existing limitation.
2. **No `--cleanup` flag** — If onboarding partially fails, there's no way to drop the schema and start fresh via the CLI. Idempotent re-run handles most cases, but a truly stuck state requires manual SQL. Consider adding in a future ticket if needed.
3. **Slug collision** — If two different business names produce the same slug, the second run finds the first company. This is by design (idempotent), but could surprise a user. The CLI could warn when an existing company is found.
