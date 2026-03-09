---
id: T-020-01
story: S-020
title: content-generation-functions
type: task
status: open
priority: high
phase: done
depends_on: [T-018-02, T-018-03]
---

## Context

Define BAML functions that generate professional website content from the extracted operator profile. The LLM writes the copy — service descriptions, tagline, "why hire us" — so the operator doesn't have to.

## Acceptance Criteria

- `baml/functions/generate_content.baml` with functions:
  - `GenerateServiceDescriptions`: takes service names + business context → full descriptions (2-3 sentences each)
  - `GenerateTagline`: takes business info → 3 tagline options (short, punchy, professional)
  - `GenerateWhyHireUs`: takes differentiators → 6 bullet points matching the landing page format
  - `GenerateMetaDescription`: takes business info → SEO meta description (≤160 chars)
- Each function has typed output matching Content domain resource schemas
- `Haul.AI.ContentGenerator` Elixir module wrapping all generation functions
- Uses Claude Haiku for cost efficiency (generation is less complex than extraction)
- Test fixtures with sample profiles → expected content structure (not exact text)
- Generated content passes Content domain Ash validations
- Token usage logged per generation call
