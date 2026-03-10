# T-033-05 Plan: async-unlock

## Step 1: Fix create_authenticated_context uniqueness

**File:** `test/support/conn_case.ex`
**Change:** Line 49 — add `System.unique_integer` to company name
**Verify:** `mix test test/haul_web/live/admin/impersonation_test.exs` (currently failing from slug conflict)

## Step 2: Flip DataCase files to async: true

**Files:** 21 DataCase test files (see structure.md for full list)
**Change:** Replace `async: false` with `async: true` in each file's `use` statement
**Verify:** `mix test --stale` after each batch

Batch approach:
- Batch A: accounts/* (3 files) + ai/edit_applier + ai/provisioner (2 files)
- Batch B: content/* (6 files)
- Batch C: onboarding + operations/* + tenant_isolation (4 files)
- Batch D: workers/* (5 files) + mix/tasks/haul/onboard_test

## Step 3: Flip ConnCase files to async: true

**Files:** 18-20 ConnCase test files
**Change:** Replace `async: false` with `async: true`
**Verify:** `mix test --stale` after each batch

Batch approach:
- Batch A: controllers (3 files)
- Batch B: admin live (2 files)
- Batch C: app live — non-rate-limiter files (7 files)
- Batch D: booking/payment/scan/tenant (6 files)
- Batch E: smoke_test

## Step 4: Flip chat_test.exs to async: true

**File:** `test/haul/ai/chat_test.exs`
**Verify:** `mix test test/haul/ai/chat_test.exs`

## Step 5: Full suite verification

Run `mix test` 3 times with different seeds:
1. `mix test --seed 0`
2. `mix test --seed 12345`
3. `mix test` (random seed)

All 3 must pass with 0 failures. Any flaky failure → revert that file to async: false and document.

## Step 6: Timing comparison

Record wall-clock time for final `mix test` run. Compare to baseline (77.3s from T-033-04).

## Testing Strategy

- **Primary verification:** `mix test --stale` after each batch (5-15s per run)
- **Final verification:** 3× full `mix test` with different seeds
- **Flaky detection:** If test passes on seed X but fails on seed Y, it's a shared-state issue
- **Revert protocol:** Any file that causes flaky failures reverts to async: false immediately
