---
id: T-018-04
story: S-018
title: extraction-tests
type: task
status: open
priority: medium
phase: done
depends_on: [T-018-03]
---

## Context

Comprehensive test suite for the extraction pipeline. Since LLM output is non-deterministic, tests use recorded fixtures but also include optional live-API integration tests gated behind an env var.

## Acceptance Criteria

- `test/haul/ai/extractor_test.exs` with fixture-based tests:
  - Full profile extraction from clean conversation
  - Partial profile extraction (missing fields correctly identified)
  - Service category inference from natural language ("I haul away old furniture" → JUNK_REMOVAL)
  - Multi-turn conversation extraction (accumulates info across messages)
  - Handles garbage/irrelevant input gracefully (returns empty profile, not crash)
  - Phone number normalization (various formats → consistent format)
  - Email validation (extracted email must be valid format)
- `test/haul/ai/profile_mapper_test.exs`:
  - OperatorProfile → Company changeset
  - OperatorProfile → SiteConfig changeset
  - ServiceOffering list → Service changesets with correct sort_order
  - Differentiators → "why hire us" content
- Optional integration tests (run with `BAML_LIVE_TESTS=1 mix test`):
  - Send real conversation to LLM, verify extraction produces valid types
  - Measure extraction latency and token usage
