---
id: S-028
title: extract-domain-logic
status: open
epics: [E-015]
---

## Extract Domain Logic for Unit Testing

Identify pure functions buried inside Ash resources, LiveView handlers, and controllers that can be extracted into standalone modules and unit-tested without the database.

## Scope

- Audit Ash resources for logic that doesn't need the data layer:
  - Validation functions (title format, slug generation, plan feature gates)
  - Computation/transformation (price calculation, content formatting, profile mapping)
  - Policy decision logic (role checks, plan checks) — separate from Ash policy DSL
- Audit LiveView modules for handler logic that could be pure functions:
  - Form parameter normalization
  - Event → state transitions (e.g., chat message processing pipeline)
  - Display formatting (currency, dates, status labels)
- Extract identified logic into domain modules (e.g., `Haul.Billing.Plans`, `Haul.Content.Formatting`)
- Write unit tests (`ExUnit.Case, async: true`) for extracted modules
- Existing integration tests remain — they become the "does the plumbing work" check
- Target: identify 20+ functions across the codebase that can be unit-tested

## Approach

This is incremental, not a rewrite. Each extraction is a small PR:
1. Copy the logic into a new module
2. Write unit tests for it
3. Call the new module from the original location
4. Verify integration tests still pass

## Tickets

- T-028-01: logic-audit — research ticket, catalog extractable pure functions across lib/
- T-028-02: extract-billing-content — extract 8-12 pure functions from billing/content/domain modules + unit tests
- T-028-03: extract-liveview-logic — extract 8-12 pure functions from LiveView handlers + unit tests

T-028-02 and T-028-03 can run in parallel after T-028-01.

## Why this matters

Every pure function extracted is a test that runs in <1ms instead of 150-200ms. It also makes the code more composable and readable — business rules are explicit rather than buried in Ash DSL callbacks.
