---
id: T-033-01
story: S-033
title: audit-mock-candidates
type: task
status: open
priority: high
phase: done
depends_on: []
---

## Context

Before converting tests, we need a complete inventory of what each test file actually needs from the DB vs. what it tests through the DB out of convenience. This ticket produces the migration plan that drives T-033-02 through T-033-05.

## Acceptance Criteria

- Produce `docs/active/work/T-033-01/audit.md` with a table covering every `DataCase` and `ConnCase` test file
- For each file, classify every `test` block as one of:
  - **DB-required** — tests DB constraints, tenant isolation, Ash policy enforcement, or multi-resource transactions
  - **Mock-feasible** — tests deterministic logic that happens to go through DB; inputs and outputs are predictable
  - **Render-only** — LiveView tests asserting on HTML/assigns, not on DB state changes
- Flag files where the entire module can drop to `ExUnit.Case, async: true`
- Flag files where some tests can be split out into a new unit test module
- Flag QA files that overlap with existing non-QA LiveView tests (list the overlapping test names)
- Estimate per-file time savings based on the `--trace` timing data

## Implementation Notes

- Run `mix test --trace` and capture full output for timing reference
- For each file, read both the test and the source module to understand what's actually being exercised
- Pay special attention to:
  - `setup` blocks that call `create_authenticated_context/0` or `Onboarding.run/1` — these are the 150–200ms-per-test cost
  - Tests that assert on return values of pure functions (string matching, map transformation, pattern matching)
  - LiveView tests where `assert html =~ "..."` is the only assertion (no DB read-back)
- Don't classify Ash validation tests as mock-feasible — Ash constraints run through the DB layer and that's intentional
- Output should be machine-readable enough that subsequent tickets can work from it without re-reading every file

## Key files to audit

**High-value DataCase (pure logic hiding behind DB):**
- `test/haul/ai/edit_applier_test.exs` (2.1s, 11 tests)
- `test/haul/ai/provisioner_test.exs` (~1.5s, ~8 tests)
- `test/haul/workers/check_dunning_grace_test.exs`
- `test/haul/workers/provision_cert_test.exs`
- `test/haul/workers/provision_site_test.exs`
- `test/haul/workers/send_booking_email_test.exs`
- `test/haul/workers/send_booking_sms_test.exs`

**High-value ConnCase (render logic behind full-stack):**
- `test/haul_web/live/preview_edit_test.exs` (5.6s, 13 tests)
- `test/haul_web/live/provision_qa_test.exs` (4.8s, 14 tests)
- `test/haul_web/live/chat_qa_test.exs` (4.0s, 25 tests)
- `test/haul_web/live/app/onboarding_live_test.exs` (2.8s, 14 tests)

**QA duplication candidates:**
- All 7 `*_qa_test.exs` files (110 tests, 22.4s total)
