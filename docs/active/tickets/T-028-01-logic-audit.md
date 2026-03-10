---
id: T-028-01
story: S-028
title: logic-audit
type: task
status: open
priority: high
phase: done
depends_on: []
---

## Context

Pure domain logic is embedded inside Ash resource modules, LiveView handlers, and controllers. This logic can't be unit-tested without standing up the full stack. Before extracting anything, we need to audit what exists and where the highest-value extractions are.

## Acceptance Criteria

- Produce `docs/active/work/T-028-01/audit.md` cataloging extractable pure functions across:
  - **Ash resources** (`lib/haul/`): validation logic, computed attributes, custom changes, preparations
  - **LiveView modules** (`lib/haul_web/live/`): event handlers with business logic, form parameter normalization, display formatting
  - **Controllers** (`lib/haul_web/controllers/`): response formatting, parameter validation
  - **Workers** (`lib/haul/workers/`): message construction, retry logic
- For each candidate, document:
  - Source file and function/callback
  - What it does (1 line)
  - Current test coverage (is it tested? only through integration?)
  - Extraction difficulty (trivial / moderate / hard)
  - Dependencies (does it call Repo? Ash? External APIs? Or is it pure?)
- Categorize candidates into:
  - **Pure functions** — no side effects, no DB, no external calls. Extract immediately.
  - **Logic with DB reads** — reads data but core logic is a transformation. Extract the transformation, keep the read at the call site.
  - **Tightly coupled** — logic interleaved with Ash DSL or LiveView socket manipulation. Not worth extracting now.
- Prioritize by: number of tests that would move from integration → unit, and code clarity improvement
- Target: identify at least 20 extractable functions, 10 of which are "pure" category

## Implementation Notes

- This is a research ticket — no code changes
- Focus on `lib/haul/` (domain) and `lib/haul_web/live/app/` (admin panel) as highest-value areas
- Skip browser QA tests and Playwright-related code — those are inherently integration-level
- Check existing unit test files (`test/haul/billing_test.exs`, `test/haul/domains_test.exs`, etc.) to see what patterns already work well
