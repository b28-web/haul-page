---
id: T-028-03
story: S-028
title: extract-liveview-logic
type: task
status: open
priority: medium
phase: done
depends_on: [T-028-01]
---

## Context

LiveView modules mix rendering, socket state management, and business logic in `handle_event/3` callbacks. Pure logic buried there can only be tested by mounting the LiveView with a real DB connection. Extracting it enables fast unit tests.

## Acceptance Criteria

- Extract 8-12 pure functions from LiveView modules into domain or helper modules
- Focus areas (confirm against T-028-01 audit):
  - Chat message processing pipeline (parameter normalization, message formatting)
  - Onboarding wizard state transitions (step validation, completion checks)
  - Billing display logic (plan comparison, feature availability, price formatting)
  - Gallery/service reordering logic (sort_order calculation)
  - Form validation helpers shared across multiple LiveViews
- Each extracted function has unit tests (`ExUnit.Case, async: true`)
- LiveView `handle_event/3` callbacks become thin dispatchers: validate params → call extracted function → update socket
- Existing LiveView integration tests still pass unchanged
- Net new test count: 20+ unit tests added

## Implementation Notes

- LiveView socket assigns are maps — extracted functions should take and return plain maps/structs, not sockets
- Pattern: `handle_event("save", params, socket)` → `MyModule.process_save(params, relevant_assigns)` → update socket with result
- Don't extract rendering logic (HEEx templates) — that's inherently a LiveView concern
- Don't extract `handle_info` callbacks that manage PubSub/process state — those need LiveView context
- T-028-02 and T-028-03 can run in parallel since they target different source files
