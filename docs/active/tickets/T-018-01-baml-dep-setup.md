---
id: T-018-01
story: S-018
title: baml-dep-setup
type: task
status: open
priority: high
phase: ready
depends_on: [T-001-06]
---

## Context

Add `baml_elixir` to the project and verify the Rustler NIF compiles on all target platforms. This is the foundational integration — everything else in E-011 depends on it.

## Acceptance Criteria

- `baml_elixir` added to `mix.exs` deps (pin to latest stable or pre-release)
- `mix deps.get && mix compile` succeeds on macOS ARM64 (dev)
- Dockerfile builds with NIF compilation (verify pre-compiled binary works on Linux x86_64)
- CI workflow compiles successfully with the NIF
- `baml/` directory at project root for `.baml` source files
- Minimal smoke test: define a trivial BAML function, call it from Elixir test with a fixture response
- LLM API key configuration: `ANTHROPIC_API_KEY` read from env in `runtime.exs`
- Document NIF compilation requirements in README or dev setup docs
- If `baml_elixir` NIF fails on any platform, document the issue and evaluate REST sidecar fallback
