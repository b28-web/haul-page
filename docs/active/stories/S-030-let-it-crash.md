---
id: S-030
title: let-it-crash
status: open
epics: [E-016]
---

## Let It Crash

Remove defensive error handling that hides bugs, loses context, and prevents supervisors and Oban from doing their job. Business logic should express the happy path. Error recovery is architectural.

## Scope

Two categories of fixes:

### Category A: Remove defensive try/rescue (6 sites)

These `try/rescue` blocks catch broad exceptions and convert them to error tuples or silently continue. In each case, the crash would be more useful than the defensive handling:

1. `lib/haul/ai/cost_tracker.ex` — `record_call/1` rescues `Ash.create()`, returns `{:error, :recording_failed}` which caller ignores. Remove rescue; let it crash. Cost tracking failure in a background context is a bug to surface, not hide.
2. `lib/haul/onboarding.ex` — `seed_content/1` wraps `Seeder.seed!/1`. Converts exception to `{:error, :content_seed, msg}`, losing the exception type. Use non-bang `seed/1` if recoverable, or let the bang crash if not.
3. `lib/haul/ai/chat/anthropic.ex` — `stream_message/2` rescues generic exceptions in a spawned Task. Should only rescue expected network errors (timeout, connection refused), not all exceptions.
4. `lib/haul/domains.ex` — `verify_dns/2` has `rescue _ -> {:error, :dns_error}`. Discards all context. Rescue specific DNS exceptions, log the actual error.
5. `lib/haul/workers/provision_cert.ex` — `send_failure_notification/2` rescues email send. Let Swoosh errors propagate; the worker can retry.
6. `lib/haul/ai/prompt.ex` — `prompts_dir/0` rescues `ArgumentError` for path fallback. Resolve at compile time with `Application.compile_env`.

### Category B: Fix error swallowing in workers (3 sites)

These workers return `:ok` on failure, preventing Oban retries:

1. `lib/haul/workers/send_booking_email.ex` — returns `:ok` when `Ash.get` fails. Should return `{:error, reason}` so Oban retries or logs a dead letter.
2. `lib/haul/workers/check_dunning_grace.ex` — `downgrade_company/1` logs warning on error but doesn't propagate. Should return error tuple.
3. `lib/haul/places/google.ex` — returns `{:ok, []}` on API errors. Should return `{:error, reason}` at the adapter level; callers decide whether empty results are acceptable.

## Tickets

- T-030-01: audit-error-handling — research ticket, read each site, classify as "remove rescue" / "narrow rescue" / "keep (boundary code)" / "fix worker return"
- T-030-02: fix-defensive-rescues — remove or narrow the 6 try/rescue blocks
- T-030-03: fix-worker-error-propagation — fix the 3 workers to propagate errors correctly

## Acceptance criteria

- Zero broad `rescue e` or `rescue _` in business logic (boundary code exempted)
- Workers return `{:error, reason}` on failure, not `:ok`
- All 845+ tests pass (some tests may need updating if they asserted on the old error-swallowing behavior)
- No new try/rescue blocks added
