---
id: T-028-02
story: S-028
title: extract-billing-content
type: task
status: open
priority: medium
phase: done
depends_on: [T-028-01]
---

## Context

T-028-01 audit identifies pure functions in billing, content, and domain logic. This ticket extracts the top-priority candidates and writes unit tests for them.

## Acceptance Criteria

- Extract 8-12 pure functions identified by the audit into standalone modules
- Each extracted function:
  - Lives in a dedicated module (e.g., `Haul.Billing.PlanLogic`, `Haul.Content.Formatting`, `Haul.Domains.Validation`)
  - Has unit tests in a corresponding `_test.exs` using `ExUnit.Case, async: true`
  - Is called from the original location (Ash resource, LiveView, controller)
  - Has zero database or external service dependencies
- New unit tests cover edge cases that may not have been tested at the integration level
- Existing integration tests still pass unchanged
- Net new test count: 30+ unit tests added
- Document extracted modules in `docs/active/work/T-028-02/` with before/after examples

## Implementation Notes

- Likely extraction targets (confirm against T-028-01 audit):
  - Plan feature gates and tier logic (already partially in `Haul.Billing`)
  - Slug generation and domain normalization (already partially in `Haul.Domains`)
  - Content markdown processing helpers
  - Form parameter coercion in LiveView handlers
  - Display formatting (currency, dates, status labels)
- Don't extract Ash validations that use `Ash.Changeset` — those are framework-coupled by design
- Don't create a module for a single function — group related logic
