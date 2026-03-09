# T-024-04 Plan: Agent Test Targeting

## Step 1: Add test targeting section to CLAUDE.md

Add a new "## Test Targeting" section after "## Code Conventions" with:

**1a. Mapping table** covering all domains:
| Domain | Source | Tests | Also run |
|--------|--------|-------|----------|
| Accounts | `lib/haul/accounts/` | `test/haul/accounts/` | `test/haul/tenant_isolation_test.exs` |
| AI | `lib/haul/ai/` | `test/haul/ai/` | — |
| Billing | `lib/haul/billing/` | `test/haul/billing_test.exs` | `test/haul_web/live/app/billing_live_test.exs` |
| Content | `lib/haul/content/` | `test/haul/content/` | — |
| Operations | `lib/haul/operations/` | `test/haul/operations/` | — |
| Payments | `lib/haul/payments/` | `test/haul/payments_test.exs` | `test/haul_web/live/payment_live_test.exs` |
| ... (all domains) |

**1b. Command examples** — 4-5 one-liners showing targeted test invocations.

**1c. Cross-cutting guidance** — when to add tenant isolation, smoke, or QA tests.

**1d. Full suite rule** — always run `mix test` before marking done.

Verify: Read back the section, ensure all 85 test files are reachable from the mapping.

## Step 2: Update RDSPI workflow

In `docs/knowledge/rdspi-workflow.md`:
- Implement phase: append "Run targeted tests after each change (see CLAUDE.md § Test Targeting for the source→test mapping)."
- Review phase: append "Run the full test suite (`mix test`) and note the result."

Verify: Read back the file, ensure additions are coherent.

## Step 3: Update `just llm` briefing

In `.just/system.just` `_llm` recipe, add to the Conventions block:
```
- Test targeting: CLAUDE.md § "Test Targeting" maps source→test files. Run targeted tests during implement, full suite before review.
```

Verify: Run `just llm` and confirm the line appears.

## Step 4: Verify targeted test timing

Run a representative targeted test command for a typical ticket scope:
```
mix test test/haul/content/ test/haul_web/controllers/page_controller_test.exs
```
Confirm it completes in under 15 seconds (AC requirement).

## Step 5: Run full test suite

Run `mix test` to verify no regressions from documentation-only changes (should be clean).

## Testing strategy
This ticket is documentation-only. No code changes, so no new tests. Verification is:
1. Targeted test runs complete in <15 seconds
2. Full suite still passes
3. Mapping table covers all domains
