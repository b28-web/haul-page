# T-017-02 Review: Cert Provisioning

## Summary

Implemented automated TLS certificate provisioning for custom domains via the Fly.io API. When a user's DNS verification succeeds, an Oban worker enqueues to add a certificate, polls for readiness, and activates the domain. Domain removal triggers a separate cleanup job.

## Files Created

| File | Purpose |
|------|---------|
| `lib/haul/domains/sandbox.ex` | Dev/test cert adapter — instant success |
| `lib/haul/domains/fly_api.ex` | Production cert adapter — Fly Machines API via Req |
| `lib/haul/workers/provision_cert.ex` | Oban worker: add/remove cert, poll, update company |
| `lib/haul/notifications/domain_email.ex` | Failure notification email template |
| `test/haul/workers/provision_cert_test.exs` | 6 tests for the worker |
| `priv/repo/migrations/20260309080000_add_domain_verified_at_to_companies.exs` | Adds domain_verified_at column |

## Files Modified

| File | Change |
|------|--------|
| `lib/haul/domains.ex` | Added CertAdapter behaviour + dispatch functions (add_cert, check_cert, remove_cert) |
| `lib/haul/accounts/company.ex` | Added domain_verified_at attribute, updated accept list |
| `lib/haul_web/live/app/domain_settings_live.ex` | Enqueue jobs on verify/remove, PubSub subscription + handler |
| `config/config.exs` | Added certs queue (3), cert_adapter default (Sandbox) |
| `config/runtime.exs` | Added FLY_API_TOKEN + FLY_APP_NAME config block |

## Test Coverage

- **6 new tests** in `provision_cert_test.exs`
  - Add flow: company gets domain_status=:active, domain_verified_at set
  - No domain set: returns :ok (no-op)
  - Non-existent company: returns error
  - PubSub broadcast: receives :domain_status_changed message
  - Remove flow: returns :ok
  - Unknown args: handled gracefully
- **488 total tests, 0 failures** — no regressions

## Architecture Decisions

1. **Adapter pattern** matches Billing, Places, SMS modules. Sandbox adapter enables testing without network.
2. **Single worker, two actions** ("add"/"remove") keeps job management simple.
3. **In-job polling** (5s × 24 = 2 min) rather than recursive job scheduling — simpler, cert provisioning is fast.
4. **PubSub broadcast** enables real-time UI updates when cert completes in background.
5. **Best-effort removal** — remove action returns :ok even on failure since domain is already cleared from DB.

## Acceptance Criteria Checklist

- [x] Oban worker: `Haul.Workers.ProvisionCert`
- [x] On DNS verification success, enqueue cert provisioning job
- [x] Job calls Fly.io API: `fly certs add` equivalent via REST API
- [x] Poll for cert readiness (5s interval, 2 min timeout)
- [x] On success: update Company `domain_verified_at`, set domain status to active
- [x] On failure: retry with exponential backoff (Oban built-in), notify operator after 3 failures
- [x] Domain removal: Oban worker calls `fly certs remove` equivalent
- [x] Fly API token stored as env var (platform-level secret)

## Open Concerns

1. **Fly API response format** — The `check_cert` response parsing in FlyApi is based on documented API structure. May need adjustment when testing against real Fly API. The sandbox adapter masks this in tests.
2. **No LiveView integration test** — The LiveView Oban enqueueing is not tested (would need Oban testing mode). T-017-03 browser QA will cover this end-to-end.
3. **Polling blocks the worker** — The 2-minute polling loop blocks an Oban worker slot. With `certs: 3` queue, this means max 3 concurrent provisioning operations. Sufficient for expected load.
4. **Email recipient** — `cert_failed/2` sends to the operator email from config, not a per-company email. This is correct for the current architecture (platform-level notification) but may need revisiting when operators have distinct contact emails.
