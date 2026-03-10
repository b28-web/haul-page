# T-030-03 Structure — Fix Worker Error Returns

## Files Modified

### 1. `lib/haul/workers/send_booking_email.ex`

- Add `alias Ash.Error.Query.NotFound` (or inline in pattern)
- Change `perform/1` error clause from `{:error, _} -> :ok` to two clauses:
  - `{:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.NotFound{}]}} -> :ok`
  - `{:error, reason} -> {:error, reason}`

### 2. `lib/haul/workers/send_booking_sms.ex`

- Same change as email worker. Identical pattern.

### 3. `lib/haul/workers/provision_cert.ex`

- Line 49: Change `:ok` to `{:error, reason}` in the remove action error clause.

### 4. `lib/haul/workers/cleanup_conversations.ex`

- `perform/1`: Replace sequential calls + unconditional `:ok` with `with` chain.
- `mark_stale_as_abandoned/1`: Change return from implicit `nil`/`:ok` to explicit `:ok` on success, `{:error, reason}` on Ash.read failure.
- `delete_old_abandoned/1`: Same return type change.

### 5. `test/haul/workers/send_booking_email_test.exs`

- Existing "returns :ok when job not found" test: **no change needed** — the test already uses a non-existent UUID, which triggers NotFound, which still returns `:ok`.

### 6. `test/haul/workers/send_booking_sms_test.exs`

- Same as email — **no change needed**.

### 7. `test/haul/workers/provision_cert_test.exs`

- Need to verify whether `Domains.remove_cert/1` can be made to fail in tests. If the test adapter always succeeds, we may need to check how the Domains module is configured for test.

### 8. `test/haul/workers/cleanup_conversations_test.exs`

- Existing tests pass unchanged (happy paths still return `:ok`).

## Files NOT Modified

- `check_dunning_grace.ex` — already propagates top-level errors correctly
- `places/google.ex` — classified "Keep" (graceful degradation)
- Test files for workers not being changed

## Module Boundaries

No new modules. No interface changes. The only external-facing change is that workers now return `{:error, reason}` on transient failures instead of `:ok`, which is purely an Oban contract concern (retries happen automatically).

## Ordering

1. Fix email worker (smallest, establishes the pattern)
2. Fix SMS worker (identical pattern)
3. Fix cert worker (one-line change)
4. Fix cleanup worker (slightly more involved — helper return types change)
5. Run targeted tests after each change
6. Run full suite at the end
