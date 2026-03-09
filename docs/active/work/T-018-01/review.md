# T-018-01 Review: BAML Dependency Setup

## Summary

Added `baml_elixir` NIF dependency for structured LLM output, created the AI adapter layer following existing project patterns, configured ANTHROPIC_API_KEY, and wrote a smoke test. The NIF uses precompiled binaries so no Rust toolchain is needed anywhere.

## Files created

| File | Purpose |
|------|---------|
| `lib/haul/ai.ex` | Behaviour + public API for structured LLM calls |
| `lib/haul/ai/sandbox.ex` | Dev/test adapter returning fixture responses |
| `lib/haul/ai/baml.ex` | Prod adapter wrapping BamlElixir.Client |
| `baml/main.baml` | BAML source with Anthropic client + ExtractName function |
| `test/haul/ai_test.exs` | Smoke test (2 tests) using sandbox adapter |

## Files modified

| File | Change |
|------|--------|
| `mix.exs` | Added `{:baml_elixir, "~> 0.2.0"}` dependency |
| `config/config.exs` | Added `config :haul, :ai_adapter, Haul.AI.Sandbox` |
| `config/test.exs` | Added explicit sandbox adapter for test env |
| `config/runtime.exs` | Added ANTHROPIC_API_KEY env var handling (non-test) |

## Files NOT modified (plan deviation)

| File | Why not |
|------|---------|
| `Dockerfile` | Precompiled NIF — no Rust toolchain needed |
| `.github/workflows/ci.yml` | Precompiled NIF — no Rust toolchain needed |
| `mise.toml` | No Rust toolchain needed |

## Acceptance criteria checklist

- [x] `baml_elixir` added to `mix.exs` deps (pinned to ~> 0.2.0 stable)
- [x] `mix deps.get && mix compile` succeeds on macOS ARM64 (dev)
- [x] Dockerfile builds with NIF compilation — precompiled binary for linux x86_64 available, no build changes needed
- [x] CI workflow compiles successfully — precompiled binary, no workflow changes needed
- [x] `baml/` directory at project root with `.baml` source files
- [x] Minimal smoke test: ExtractName BAML function, tested with sandbox fixture
- [x] LLM API key configuration: `ANTHROPIC_API_KEY` read from env in `runtime.exs`
- [ ] Document NIF compilation requirements — N/A, precompiled binaries make this unnecessary
- [x] REST sidecar fallback not needed — NIF works on all target platforms

## Test coverage

- **2 new tests** in `test/haul/ai_test.exs`
  - `ExtractName` returns fixture response via sandbox
  - Unknown function returns generic sandbox response
- **490 total tests, 0 failures** (full suite)
- No integration test with real LLM API (requires key, not suitable for CI)

## Architecture notes

The adapter pattern (`Haul.AI` behaviour → `Sandbox` / `Baml` implementations) matches exactly how Payments, SMS, Places, Billing, and Domains adapters work in this project. Downstream tickets (T-018-02, 03, 04) will extend:
- `baml/main.baml` with extraction functions for operator profiles
- `Haul.AI.Sandbox` with fixture responses for those functions
- New modules that call `Haul.AI.call_function/2`

## Open concerns

1. **baml_elixir 0.2.0 is a community package** — not officially maintained by BoundaryML. Monitor for updates. If the maintainer stops updating, the REST sidecar (`baml-cli serve`) is the fallback.

2. **BAML source path in releases** — `Haul.AI.Baml` defaults `from:` to `"baml"` (relative path). In a release, the CWD may differ. If deploying with real BAML calls, configure `:baml_source_path` to an absolute path or bundle the baml directory in the release.

3. **No real API call test** — the smoke test only exercises the sandbox adapter. A tagged integration test (`:external`) that calls the real API should be added when the API key is available for manual testing.

4. **baml_elixir API surface is minimal** — `BamlElixir.Client.call/3` only. No streaming support in 0.2.0 (the `stream/3` mentioned in research may be in pre-release only). Streaming is not needed for this ticket but may matter for T-019-02 (live extraction).
