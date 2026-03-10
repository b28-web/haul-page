---
id: S-029
title: test-tier-conventions
status: open
epics: [E-015]
---

## Test Tier Conventions

Document and enforce the 3-tier test model so new code defaults to the right level.

## Scope

- Define the tiers in CLAUDE.md and a new `docs/knowledge/test-architecture.md`:
  - **Tier 1 — Unit** (`ExUnit.Case, async: true`): pure logic, transformations, validations. No DB, no HTTP. Target: <1ms per test.
  - **Tier 2 — Resource** (`DataCase, async: false`): Ash actions, policies, constraints, multi-tenant isolation. Real DB, no HTTP. Uses factories. Target: <50ms per test.
  - **Tier 3 — Integration** (`ConnCase, async: false`): LiveView rendering, controller responses, user flows. Real DB + HTTP. Uses factories + `setup_all`. Target: <200ms per test.
- Add a mix task or script that reports the test pyramid shape:
  - Count of tests per tier
  - Ratio (target: 40% unit / 30% resource / 30% integration)
  - Files with no tier annotation
- Update `just llm` to include test tier guidance for agent sessions
- Add test tier to the RDSPI workflow review checklist: "Are new tests at the lowest viable tier?"

## Enforcement

Not a hard gate — this is convention, not compilation. The mix task reports the shape so drift is visible. Agents and developers choose the tier when writing new tests. The goal is that unit tests are the default, not the exception.

## Tickets

- T-029-01: document-test-tiers — create test-architecture.md, update CLAUDE.md + `just llm` + RDSPI workflow
- T-029-02: pyramid-reporter — mix task that reports test pyramid shape + `just test-pyramid` recipe

## Why last

This story codifies what S-027 and S-028 establish. It's documentation + tooling, not code changes. It should land after the factory layer and extraction patterns prove themselves.
