# T-008-04 Structure — Browser QA for Payments

## Overview

This is a QA-only ticket. No source code files are created or modified. All work is browser interaction via Playwright MCP and artifact documentation.

## Files Created

| File | Purpose |
|------|---------|
| `docs/active/work/T-008-04/research.md` | Research artifact |
| `docs/active/work/T-008-04/design.md` | Design artifact |
| `docs/active/work/T-008-04/structure.md` | This file |
| `docs/active/work/T-008-04/plan.md` | Step-by-step QA plan |
| `docs/active/work/T-008-04/progress.md` | QA execution log with pass/fail per step |
| `docs/active/work/T-008-04/review.md` | Summary and findings |

## Files Modified

None. QA-only ticket.

## Prerequisites (pre-test setup)

1. **Dev server:** Must be running at `http://localhost:4000`
2. **Tenant:** Company must exist (slug: `junk-and-handy` or similar) — the `tenant_*` schema must have a `jobs` table
3. **Job:** At least one Job in `:lead` state with no `payment_intent_id` — needed for the pending payment page

If no Job exists, create one via booking form (`/book`) or IEx:
```elixir
Ash.create!(Haul.Operations.Job, %{
  customer_name: "Test Customer",
  customer_phone: "555-0100",
  address: "123 Test St",
  item_description: "Old couch"
}, action: :create_from_online_booking, tenant: "tenant_junk-and-handy")
```

## Test Flow

```
Navigate /pay/{job_id}     → snapshot → verify pending state
Navigate /pay/{bad_uuid}   → snapshot → verify not-found state
Resize 375x812             → navigate → snapshot → verify mobile layout
Check console messages     → verify no JS errors
```

## Acceptance Criteria Mapping

| Criterion | How verified |
|-----------|-------------|
| Payment Element renders without JS errors | Snapshot shows `#stripe-payment` container + no console errors |
| Test card payment completes successfully | Unit tests (T-008-02) — browser QA cannot fill Stripe iframe |
| Success state displayed after payment | Unit tests verify `:succeeded` render branch |
| No 500 errors in server logs | Check dev server output during QA |
