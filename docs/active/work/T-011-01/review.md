# T-011-01 Review: Onboarding Runbook

## Summary

Created `docs/knowledge/operator-onboarding.md` — a step-by-step runbook for deploying a new operator instance on Fly.io.

## Files Changed

| File | Action | Lines |
|------|--------|-------|
| `docs/knowledge/operator-onboarding.md` | Created | ~250 |

No code changes. No tests needed. Documentation-only ticket.

## Acceptance Criteria Check

| Criterion | Status |
|-----------|--------|
| `docs/knowledge/operator-onboarding.md` with numbered steps | ✅ |
| Step 1: Create Fly app (`fly apps create`) | ✅ |
| Step 2: Create Neon DB (separate project per operator) | ✅ |
| Step 3: Set secrets (`fly secrets set ...`) | ✅ |
| Step 4: Deploy (`fly deploy --app ...`) | ✅ |
| Step 5: Run migrations (auto via `migrate_and_start`, manual fallback) | ✅ |
| Step 6: Seed content (company creation + content seeder via release eval) | ✅ |
| Step 7: Add custom domain (`fly certs add`) | ✅ |
| Step 8: Verify (health check, landing page, booking form, print view) | ✅ |
| Estimated time: under 30 minutes | ✅ (stated at top) |
| All required env vars with descriptions and examples | ✅ (3 tables) |
| Rollback steps | ✅ (release rollback + migration rollback) |
| Teardown steps | ✅ (destroy app, delete Neon project, remove DNS) |

## Test Coverage

N/A — documentation ticket. No automated tests.

Validation was done by cross-referencing:
- All env var names against `config/runtime.exs`
- Module/function paths against source code
- Release script paths against Dockerfile and `rel/overlays/bin/`
- flyctl command syntax against current CLI conventions

## Open Concerns

1. **DEPLOYMENT.md overlap** — The existing `DEPLOYMENT.md` covers single-instance deploy. The new runbook covers multi-operator onboarding. Some content overlaps (secrets, custom domains). Could consolidate later, but both serve different audiences for now.

2. **Content seeding via eval is verbose** — The release eval commands for company creation and content seeding are multi-line Elixir expressions. T-014-01 (`mix haul.onboard`) will automate this, but the manual runbook needs these spelled out.

3. **No automated verification** — Step 8 is manual (curl + browser). A future smoke test script could automate this, but that's out of scope for this ticket.

4. **OPERATOR_NAME vs OPERATOR_BUSINESS_NAME** — The existing `DEPLOYMENT.md` references `OPERATOR_NAME` but `runtime.exs` uses `OPERATOR_BUSINESS_NAME`. The runbook uses the correct `OPERATOR_BUSINESS_NAME`. `DEPLOYMENT.md` should be updated to match (minor, not blocking).

## Downstream Impact

- **T-014-01 (mix haul.onboard)** — This runbook is the specification for what the CLI tool will automate. The steps, env vars, and verification criteria should map 1:1.
- **T-011-02 (customer-seed-content)** — Related but separate. That ticket covers customizing seed content per operator; this runbook uses the default content pack.
- **T-011-03 (monitoring-setup)** — The runbook mentions `fly logs` and `fly dashboard` but doesn't cover monitoring setup in depth. That's T-011-03's job.
