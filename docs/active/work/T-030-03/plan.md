# T-030-03 Plan — Fix Worker Error Returns

## Step 1: Fix SendBookingEmail

**Change:** In `perform/1`, replace the single `{:error, _} -> :ok` clause with two clauses:
- NotFound → `:ok` (job was deleted, don't retry)
- Other errors → `{:error, reason}` (DB issues, retry via Oban)

**Test:** `mix test test/haul/workers/send_booking_email_test.exs`
- Existing "returns :ok when job not found" test should still pass (non-existent UUID → NotFound → `:ok`)

## Step 2: Fix SendBookingSMS

**Change:** Identical pattern change as Step 1.

**Test:** `mix test test/haul/workers/send_booking_sms_test.exs`

## Step 3: Fix ProvisionCert remove action

**Change:** Line 49, change `:ok` to `{:error, reason}`.

**Test:** `mix test test/haul/workers/provision_cert_test.exs`
- Existing tests only cover successful removal. Check if test adapter for Domains can be configured to fail.

## Step 4: Fix CleanupConversations

**Change:**
- `perform/1`: Use `with` chain instead of sequential calls
- `mark_stale_as_abandoned/1`: Return `:ok` on success, `{:error, reason}` on Ash.read failure
- `delete_old_abandoned/1`: Same return type change

**Test:** `mix test test/haul/workers/cleanup_conversations_test.exs`

## Step 5: Full test suite

**Run:** `mix test`
**Verify:** All 845+ tests pass.

## Verification Criteria

- [x] All 4 audit sites fixed
- [x] Workers return `{:error, reason}` on transient failures
- [x] Workers return `:ok` on expected conditions (not-found = booking cancelled)
- [x] No test regressions
- [x] Full suite passes
