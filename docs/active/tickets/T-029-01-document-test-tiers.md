---
id: T-029-01
story: S-029
title: document-test-tiers
type: task
status: open
priority: medium
phase: done
depends_on: [T-027-01, T-028-01]
---

## Context

The codebase now has three test tiers in practice but no documentation guiding developers or agents on which tier to use. New tests default to integration level because that's what existing tests show.

## Acceptance Criteria

- Create `docs/knowledge/test-architecture.md` documenting:
  - The 3-tier model with examples from the codebase
  - Decision tree: "Which tier should my test use?"
  - Factory usage patterns (from S-027)
  - `setup_all` vs `setup` guidance
  - When `async: true` is safe
  - Anti-patterns: "Signs your test is at the wrong tier"
- Update CLAUDE.md "Test Targeting" section:
  - Add tier definitions (1-2 lines each)
  - Add rule: "Default to the lowest viable tier. Unit > Resource > Integration."
  - Link to `docs/knowledge/test-architecture.md` for details
- Update `just llm` output (`.just/system.just` `_llm` recipe):
  - Add test tier summary to the agent briefing
- Update RDSPI workflow (`docs/knowledge/rdspi-workflow.md`):
  - Add to review phase checklist: "Are new tests at the lowest viable tier?"

## Implementation Notes

- This is a documentation ticket — no test code changes
- Use concrete examples from the codebase (e.g., "billing_test.exs is a good Tier 1 example")
- Keep the decision tree simple: "Does it need the DB? No → Tier 1. Does it need HTTP? No → Tier 2. Yes → Tier 3."
