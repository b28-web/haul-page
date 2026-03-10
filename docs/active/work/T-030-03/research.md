# T-030-03 Research — Fix Worker Error Returns

## Scope

The T-030-01 audit identified 4 "Fix return" sites where Oban workers return `:ok` on failure, preventing retries. This ticket fixes all 4.

## Audit Findings (from T-030-01)

| # | File | Line | Issue |
|---|------|------|-------|
| 9 | `workers/send_booking_email.ex` | 21-22 | `{:error, _} -> :ok` swallows all Ash.get errors |
| 10 | `workers/send_booking_sms.ex` | 18-19 | Identical pattern to email worker |
| 11 | `workers/provision_cert.ex` | 47-49 | Cert removal failure returns `:ok` |
| 14 | `workers/cleanup_conversations.ex` | 13-20 | `perform/1` always returns `:ok`, helpers swallow errors |

## File Analysis

### 1. SendBookingEmail (`lib/haul/workers/send_booking_email.ex`)

- 25 lines. Oban worker, queue: `:notifications`, max_attempts: 3
- `perform/1` calls `Ash.get(Job, job_id, tenant: tenant)`
- On success: sends operator alert + optional customer confirmation, returns `:ok`
- On error: **any** `{:error, _}` returns `:ok`
- Problem: DB errors (connection timeout, pool exhaustion) are conflated with "job not found"
- Ash.get not-found returns: `{:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.NotFound{}]}}`
- Also: `Mailer.deliver()` return value is ignored (lines 13, 16). Not in scope — email delivery errors should not block the worker (same pattern as billing webhook, classified "Keep" in audit).

### 2. SendBookingSMS (`lib/haul/workers/send_booking_sms.ex`)

- 22 lines. Identical pattern to email worker.
- `SMS.send_sms()` return value ignored (line 15). Same rationale — SMS is best-effort.

### 3. ProvisionCert remove action (`lib/haul/workers/provision_cert.ex:41-51`)

- The "add" action already properly propagates errors (lines 22-28). Only "remove" is broken.
- `Domains.remove_cert(domain)` failure returns `:ok` on line 49.
- Risk: dangling certs, routing conflicts. Transient API failures won't retry.
- Fix is trivial: change `:ok` to `{:error, reason}`.

### 4. CleanupConversations (`lib/haul/workers/cleanup_conversations.ex`)

- 64 lines. Two helper functions: `mark_stale_as_abandoned/1`, `delete_old_abandoned/1`.
- Both call `Ash.read()` then process results. Both log errors but return nothing meaningful.
- `perform/1` ignores helper returns and always returns `:ok`.
- Problem: if DB is down, zero cleanup happens but job is marked successful.
- Secondary: individual `Ash.update` and `Ash.destroy` failures within the Enum.each are logged but don't stop processing. This is acceptable — partial progress is better than all-or-nothing for batch operations. The critical fix is propagating `Ash.read` failures.

### 5. CheckDunningGrace — NOT in scope

- The audit classified this as "Keep" at the top level. `perform/1` already returns `{:error, reason}` when `list_companies_past_grace` fails.
- `downgrade_company/1` logs failures for individual companies but doesn't propagate. This is the same batch pattern as CleanupConversations — acceptable for individual item failures within a batch.
- Ticket AC mentions it but the audit says it's already correct. Deferring to audit.

### 6. Places.Google — NOT in scope

- Audit classified as "Keep" (graceful degradation for autocomplete UI).
- Ticket implementation notes confirm: "not a worker but an adapter."

## Existing Tests

| Test file | Tests | Error path coverage |
|-----------|-------|-------------------|
| `send_booking_email_test.exs` | 3 tests | Line 80-86: asserts `:ok` on missing job — **must update** |
| `send_booking_sms_test.exs` | 2 tests | Line 55-61: asserts `:ok` on missing job — **must update** |
| `provision_cert_test.exs` | 5 tests | No remove-error test — **must add** |
| `cleanup_conversations_test.exs` | 4 tests | No error path tests — happy paths only |
| `check_dunning_grace_test.exs` | 3 tests | No error path tests — not in scope |

## Ash.get Error Shape

```elixir
# Not found:
{:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.NotFound{...}]}}

# DB/connection error would be different error type
```

Pattern match: `{:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.NotFound{}]}}` for not-found.

## Oban Return Value Semantics

| Return | Behavior |
|--------|----------|
| `:ok` / `{:ok, value}` | Job complete |
| `{:error, reason}` | Job failed, retry up to max_attempts |
| `{:cancel, reason}` | Job cancelled, no retries |
| `{:snooze, seconds}` | Reschedule after delay |
