---
id: T-018-03
story: S-018
title: extraction-function
type: task
status: open
priority: high
phase: ready
depends_on: [T-018-02]
---

## Context

Build the BAML function that takes a conversation transcript and extracts a typed OperatorProfile. This is the core AI capability — turning a freeform chat into structured data.

## Acceptance Criteria

- `baml/functions/extract_profile.baml`:
  - Input: conversation transcript (string)
  - Output: OperatorProfile (typed)
  - Prompt: extract all business information from the conversation, infer ServiceCategory from descriptions, mark unknown fields as null
- `Haul.AI.Extractor.extract_profile/1` Elixir wrapper:
  - Accepts conversation transcript string
  - Returns `{:ok, %OperatorProfile{}}` or `{:error, reason}`
  - Handles LLM API errors, timeouts, rate limits
  - Retries once on transient failure
- `Haul.AI.Extractor.validate_completeness/1`:
  - Takes an OperatorProfile, returns list of missing required fields
  - Used to drive "we still need..." UI feedback
- Test fixtures: 5+ sample conversations covering:
  - Complete information in one message
  - Information spread across multiple messages
  - Ambiguous service descriptions that need category inference
  - Missing required fields (partial extraction)
  - Irrelevant conversation mixed with business info
- Tests use recorded LLM responses (not live API calls) for CI reliability
