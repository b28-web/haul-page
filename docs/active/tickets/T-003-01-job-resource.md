---
id: T-003-01
story: S-003
title: job-resource
type: task
status: open
priority: high
phase: ready
depends_on: [T-004-01]
---

## Context

Define the Job Ash resource with the `:lead` state as the minimum viable state machine. The booking form needs to create a Job — this is the resource it writes to.

## Acceptance Criteria

- `Haul.Operations.Job` Ash resource with AshStateMachine
- Minimum attributes: customer_name, customer_phone, customer_email, address, item_description, preferred_dates, state
- State machine starts at `:lead` (other states defined but transitions not yet implemented beyond `:lead`)
- `:create_from_online_booking` action creates a Job in `:lead` state
- Migration generated and runs successfully
- Resource compiles and action is callable from IEx
