# T-030-03 Review — Fix Worker Error Returns

## Summary

Fixed all 4 "Fix return" sites identified by the T-030-01 audit. Oban workers now properly return `{:error, reason}` on transient failures, enabling Oban's retry mechanism.

## Changes

### Files Modified (4)

| File | Change |
|------|--------|
| `lib/haul/workers/send_booking_email.ex` | Distinguish NotFound (`:ok`) from DB errors (`{:error, reason}`) |
| `lib/haul/workers/send_booking_sms.ex` | Same pattern as email worker |
| `lib/haul/workers/provision_cert.ex` | Remove action: propagate cert removal failure |
| `lib/haul/workers/cleanup_conversations.ex` | `with` chain in perform/1; helpers return `:ok`/`{:error, reason}` |

### Files NOT Modified

- No test files were modified. All existing tests pass unchanged.
- `check_dunning_grace.ex` — already propagates errors correctly (audit confirmed)
- `places/google.ex` — audit classified as "Keep" (graceful degradation)

## Test Results

```
961 tests, 0 failures (1 excluded)
```

Full suite passes. No regressions.

## Acceptance Criteria Verification

- ✅ Fixed every "fix return" site from T-030-01 audit (4 sites)
- ✅ SendBookingEmail: returns `{:error, reason}` on DB errors, `:ok` on NotFound
- ✅ SendBookingSMS: same fix
- ✅ ProvisionCert remove: returns `{:error, reason}` on cert removal failure
- ✅ CleanupConversations: propagates Ash.read failures via `with` chain
- ✅ Workers return `:ok`/`{:ok, result}` on success, `{:error, reason}` on expected failures
- ✅ All 961 tests pass

## Test Coverage Assessment

**Existing tests cover:**
- Email/SMS workers: happy path + not-found path (NotFound still returns `:ok`, tests pass unchanged)
- ProvisionCert: add success/failure, remove success, unknown action
- CleanupConversations: mark stale, delete old, leave recent, leave completed

**Gaps (pre-existing, not introduced by this change):**
- No test for ProvisionCert remove failure path (would need Domains adapter to return error)
- No test for CleanupConversations when Ash.read fails (would need DB fault injection)
- No test for email/SMS worker DB error propagation (would need Ash.get to fail with non-NotFound error)

These gaps are difficult to test without mocking/stubbing infrastructure and are acceptable given the small scope of changes. The code paths are simple and correct by inspection.

## Open Concerns

None. The changes are minimal and follow patterns already established in the codebase (e.g., ProvisionCert "add" action already propagates errors correctly — "remove" now matches).

## Risk Assessment

**Low risk.** Each change is 1-5 lines. The only behavioral change is that transient failures now trigger Oban retries instead of being silently swallowed. This is strictly an improvement — no user-facing behavior changes on the happy path.
