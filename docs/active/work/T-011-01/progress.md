# T-011-01 Progress: Onboarding Runbook

## Completed

- [x] Research phase — mapped deployment infrastructure, env vars, release scripts, multi-tenancy
- [x] Design phase — decided on separate Neon projects, `--app` flag, release eval for seeding
- [x] Structure phase — defined document outline and sections
- [x] Plan phase — single implementation step (write the doc), validation criteria
- [x] Implementation — wrote `docs/knowledge/operator-onboarding.md`
  - 8 numbered steps matching acceptance criteria
  - All env vars documented with descriptions and examples
  - Rollback and full teardown sections
  - Troubleshooting section (4 common issues)
  - Cost estimate per operator

## Deviations from Plan

None. Straightforward docs-only ticket.

## Validation

- Env var names cross-checked against `config/runtime.exs`:
  - `OPERATOR_BUSINESS_NAME` ✓ (line 29)
  - `OPERATOR_PHONE` ✓ (line 30)
  - `OPERATOR_EMAIL` ✓ (line 31)
  - `OPERATOR_TAGLINE` ✓ (line 32)
  - `OPERATOR_SERVICE_AREA` ✓ (line 33)
  - `OPERATOR_COUPON_TEXT` ✓ (line 34)
  - `DATABASE_URL` ✓ (line 69)
  - `SECRET_KEY_BASE` ✓ (line 90)
  - `PHX_HOST` ✓ (line 97)
  - All optional integration vars verified
- Release eval paths verified: `Haul.Release.migrate()`, `Haul.Content.Seeder.seed!/1`
- Module paths verified: `Haul.Accounts.Company`, `Haul.Accounts.Changes.ProvisionTenant`
- Release script path `/app/bin/haul` matches Dockerfile structure
