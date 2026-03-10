---
id: T-030-03
story: S-030
title: fix-worker-errors
type: task
status: open
priority: medium
phase: done
depends_on: [T-030-01]
---

## Context

Oban workers silently return `:ok` on failure, preventing retries. Oban's retry mechanism only triggers on `{:error, reason}` or crashes. When a worker swallows an error and returns `:ok`, Oban considers the job successful and moves on.

## Acceptance Criteria

- Fix every worker site classified as "fix return" by the T-030-01 audit
- Known targets (confirm against audit):
  1. `SendBookingEmail` — return `{:error, :job_not_found}` when `Ash.get` fails instead of `:ok`
  2. `CheckDunningGrace` — propagate `downgrade_company/1` errors as `{:error, reason}`
  3. `Places.Google` — return `{:error, reason}` on API errors instead of `{:ok, []}`
- Oban worker `perform/1` callbacks return:
  - `:ok` or `{:ok, result}` on success
  - `{:error, reason}` on expected failures (triggers retry with backoff)
  - Crash on unexpected failures (triggers retry immediately)
- Update tests that assert on old behavior (e.g., tests expecting `{:ok, []}` from Places.Google)
- Verify Oban retry behavior with the corrected return values
- All 845+ tests pass

## Implementation Notes

- Places.Google is not a worker but an adapter — its callers (LiveView autocomplete) need to handle `{:error, reason}` gracefully in the UI (show "suggestions unavailable" instead of empty dropdown)
- For workers: check if `max_attempts` is configured appropriately — some jobs shouldn't retry forever
- Consider adding `{:snooze, seconds}` for transient failures that should retry after a delay
