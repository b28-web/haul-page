---
id: S-018
title: baml-foundation
status: open
epics: [E-011, E-004]
---

## BAML Foundation (Phase 1)

Integrate `baml_elixir` into the Phoenix app and define the BAML type system that maps to operator profiles. Build the extraction pipeline that takes unstructured text and produces typed Elixir structs ready for Ash resource creation.

## Scope

- Add `baml_elixir` dep, verify NIF compiles for dev (macOS ARM64) and prod (Linux x86_64 in Docker)
- Define `.baml` files with types mirroring: OperatorProfile, ServiceOffering, BusinessDetails, ServiceArea
- BAML extraction function: conversation transcript → OperatorProfile struct
- BAML validation function: OperatorProfile → list of missing/invalid fields
- Elixir module `Haul.AI.Extractor` that wraps BAML calls with error handling and retries
- Unit tests with sample conversation transcripts → expected typed output
- LLM API key configuration via runtime env vars (ANTHROPIC_API_KEY)
- CI: verify NIF compiles, BAML types generate, extraction tests pass (with recorded fixtures, not live API calls)
