---
id: T-020-04
story: S-020
title: cost-tracking
type: task
status: open
priority: medium
phase: done
depends_on: [T-020-02]
---

## Context

Track LLM token usage and cost per onboarding session. The free tier must be sustainable — if AI onboarding costs $2 per signup, the unit economics don't work. Target: <$0.10 per onboarding.

## Acceptance Criteria

- `Haul.AI.CostTracker` module:
  - Logs every BAML function call with: function name, model used, input tokens, output tokens, estimated cost
  - Aggregates per-session totals (linked to Conversation record)
  - Aggregates platform-wide daily/monthly totals
- Cost estimates use published per-token pricing (configurable per model)
- Dashboard query: average cost per onboarding, cost trend over time
- Alert threshold: if single session exceeds $0.50, log warning
- Monthly budget alert: if total AI costs exceed configurable threshold, notify admin
- Model selection strategy documented: Haiku for extraction ($cheap), Sonnet for generation ($moderate)
- Metrics available via Telemetry events (`:haul, :ai, :call` with token/cost metadata)
