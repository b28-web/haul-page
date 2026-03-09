# T-007-05 Review — Browser QA for Notifications

## Summary

Browser QA for the notifications story (S-007) is **PASS**. The end-to-end flow from booking submission through notification delivery works correctly. Both email notifications appear in the Swoosh dev mailbox with correct content, SMS is logged by the sandbox adapter, and both Oban workers complete successfully with no failures.

## What Was Tested

| Test | Result |
|------|--------|
| Booking form loads at `/book` | PASS |
| Form accepts and validates input | PASS |
| Submission shows confirmation screen | PASS |
| Operator alert email sent to operator address | PASS |
| Customer confirmation email sent to customer | PASS |
| Email content includes all submitted details | PASS |
| SMS sandbox logs notification | PASS |
| Oban workers complete without failure | PASS |
| No 500 errors during test session | PASS |

## Files Changed

**None.** This was a QA-only ticket. No code changes were made.

## Dev Environment Issues Found

Two dev environment setup issues were encountered and resolved during QA:

### 1. Missing `payment_intent_id` column

The T-008 payments work added a `payment_intent_id` attribute to the Job Ash resource and created a tenant migration, but the migration hadn't been applied to the dev database. This is a **dev setup gap**, not a code bug.

**Root cause:** `Haul.Repo.all_tenants/0` is undefined, so `mix ash_postgres.migrate --tenants` fails. Tenant migrations cannot be applied automatically.

**Impact:** Any dev environment that hasn't manually run the tenant migration will fail on booking submission.

**Recommendation:** Define `all_tenants/0` on `Haul.Repo` to enable automatic tenant migration. This should be addressed in a follow-up ticket (likely T-012 tenant routing work, which deals with multi-tenancy).

### 2. Oban supervisor crash on startup

If the dev server starts before all migrations are applied, Oban's supervisor may fail to initialize. The server continues running (health check passes) but Oban workers can't be enqueued.

**Impact:** Silent failure — booking submissions crash with an unhelpful error about Oban not running.

**Recommendation:** Ensure `mix setup` or `just dev` runs all migrations (including tenant migrations) before starting the server.

## Test Coverage

- **Unit/integration tests:** 164 tests passing (existing coverage from T-007-01 through T-007-04)
- **Browser QA:** This ticket — end-to-end verification from UI to notification delivery
- **Coverage gaps:** None identified. The notification pipeline is well-tested at unit, integration, and browser levels.

## Open Concerns

1. **`Haul.Repo.all_tenants/0` not defined** — tenant migrations must be applied manually. This will become a bigger issue as more tenant migrations are added. Should be addressed in the tenant routing story (S-012).

2. **Dev setup fragility** — the dev server can start in a partially-functional state if migrations are missing. A guard in `mix setup` or application startup would help.

## Acceptance Criteria Verification

- [x] Booking submission triggers notification workers (visible in logs) — **Confirmed via Oban jobs table: both workers completed**
- [x] Swoosh dev mailbox shows both customer confirmation and operator alert — **Confirmed: 2 emails with correct recipients, subjects, and content**
- [x] No Oban worker failures in server logs — **Confirmed: both jobs state=completed, no errors**
- [x] SMS sandbox adapter logs the message (visible in dev log) — **Confirmed: `[SMS Sandbox] To: ...` visible in browser console**
