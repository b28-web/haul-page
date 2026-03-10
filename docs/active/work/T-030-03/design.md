# T-030-03 Design — Fix Worker Error Returns

## Decision Summary

Fix 4 "Fix return" sites identified by the T-030-01 audit. Each fix is straightforward — change error-swallowing returns to proper `{:error, reason}` returns so Oban can retry.

## Site-by-Site Design

### 1 & 2. SendBookingEmail + SendBookingSMS — Distinguish not-found from DB errors

**Option A: Pattern match on Ash.Error.Invalid wrapping NotFound**
```elixir
case Ash.get(Job, job_id, tenant: tenant) do
  {:ok, job} -> ...
  {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.NotFound{}]}} -> :ok
  {:error, reason} -> {:error, reason}
end
```
Pro: Precise. Only not-found returns `:ok`.
Con: Coupled to Ash error struct internals.

**Option B: Helper function using Ash.Error.match/2**
Pro: Uses Ash's public API for error matching.
Con: More indirection for a simple check.

**Option C: Catch all errors, return `{:error, reason}`**
Pro: Simplest. Any failure triggers retry.
Con: Not-found jobs will retry 3 times before giving up. A deleted job won't reappear.

**Decision: Option A.** The Ash.Error struct shape is stable across Ash 3.x. The pattern match is clear and handles both cases correctly. A not-found job (booking cancelled, race condition) should not retry — it would waste 3 attempts. A DB error should retry.

### 3. ProvisionCert remove action — Propagate error

Only one sensible approach: change `:ok` to `{:error, reason}` on line 49.

No alternatives to evaluate. The "add" action already does this correctly (line 28). Consistency.

### 4. CleanupConversations — Propagate read failures

**Option A: `with` chain in perform/1**
```elixir
def perform(%Oban.Job{}) do
  cutoff = ...
  with :ok <- mark_stale_as_abandoned(cutoff),
       :ok <- delete_old_abandoned(cutoff) do
    :ok
  end
end
```
Helpers return `:ok` on success, `{:error, reason}` on Ash.read failure.
Pro: Clean, idiomatic. `with` propagates first error automatically.
Con: Requires changing helper return types.

**Option B: Accumulate errors, return first**
```elixir
results = [mark_stale_as_abandoned(cutoff), delete_old_abandoned(cutoff)]
case Enum.find(results, &match?({:error, _}, &1)) do
  nil -> :ok
  error -> error
end
```
Pro: Both operations always run even if the first fails.
Con: More complex. If DB is down, both will fail — running both doesn't help.

**Decision: Option A.** The `with` chain is idiomatic Elixir. If `mark_stale_as_abandoned` fails (DB down), there's no point running `delete_old_abandoned` — it will also fail. Short-circuiting is correct here.

**Individual item failures within helpers:** Keep the current behavior — log and continue. A single conversation failing to update shouldn't prevent processing the rest. Only propagate the initial `Ash.read` failure.

## Test Strategy

1. **SendBookingEmail/SMS not-found tests:** Change assertion from `:ok` to `:ok` (still `:ok` — the behavior for not-found is preserved). The test already uses a random UUID, which triggers NotFound. No change needed to the test assertion — it should still be `:ok`.

   Wait — re-reading: the test uses `Ash.UUID.generate()` which produces a non-existent ID. Ash.get returns `{:error, %Ash.Error.Invalid{errors: [%NotFound{}]}}`. After our fix, this matches the NotFound clause and still returns `:ok`. **Test passes unchanged.**

2. **ProvisionCert remove error:** Add a test that stubs `Domains.remove_cert/1` to return `{:error, :api_timeout}` and asserts `{:error, :api_timeout}`.

   Actually — looking at the test, it uses the real test adapter for Domains. The test stub for `remove_cert` probably always succeeds. Let me check what the Domains adapter does in test.

3. **CleanupConversations:** The existing tests will still pass because they exercise happy paths. Add an error propagation test if feasible (would require a way to make Ash.read fail).

## Scope Boundaries

- **In scope:** The 4 "Fix return" sites from the audit.
- **Out of scope:** Mailer.deliver() return values in email worker (audit "Keep"), SMS.send_sms return value (best-effort), Places.Google (audit "Keep"), CheckDunningGrace downgrade_company (audit "Keep" at top level).
- **Not adding `{:snooze, seconds}`:** Ticket notes suggest considering it, but the standard `{:error, reason}` with Oban's exponential backoff is sufficient. Snooze adds complexity without clear benefit for these workers.
