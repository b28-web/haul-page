# T-018-01 Progress: BAML Dependency Setup

## Completed

### Step 1: Add baml_elixir dependency ✓
- Added `{:baml_elixir, "~> 0.2.0"}` to mix.exs
- `mix deps.get` resolved successfully
- `mix compile` succeeded — **NIF uses precompiled binaries via rustler_precompiled**
- No Rust toolchain needed! Precompiled for aarch64-apple-darwin and x86_64-unknown-linux-gnu

### Step 2: Create baml/ directory ✓
- Created `baml/main.baml` with Anthropic client config and `ExtractName` function
- Defines `PersonName` type with first_name/last_name

### Step 3: Create AI adapter modules ✓
- `lib/haul/ai.ex` — behaviour + public API (call_function/2)
- `lib/haul/ai/sandbox.ex` — returns fixture responses for dev/test
- `lib/haul/ai/baml.ex` — wraps BamlElixir.Client for prod

### Step 4: Add configuration ✓
- `config/config.exs`: default `Haul.AI.Sandbox`
- `config/test.exs`: explicit `Haul.AI.Sandbox`
- `config/runtime.exs`: `ANTHROPIC_API_KEY` env var → switches to `Haul.AI.Baml` (non-test only)

### Step 5: Write smoke test ✓
- `test/haul/ai_test.exs` — 2 tests passing (ExtractName fixture + unknown function)

### Step 6: Dockerfile ✓
- No changes needed — precompiled NIF downloaded during deps.compile

### Step 7: CI workflow ✓
- No changes needed — precompiled NIF works without Rust toolchain

### Step 8: Full test suite ✓
- `mix compile --warnings-as-errors` — clean
- `mix test` — 490 tests, 0 failures
- `mix format` — clean

## Deviations from plan
- **No Rust toolchain needed**: baml_elixir 0.2.0 uses rustler_precompiled with pre-built binaries for both macOS ARM64 and Linux x86_64. This eliminated the need for Dockerfile and CI changes.
- **runtime.exs guard**: Added `config_env() != :test` guard to prevent ANTHROPIC_API_KEY from overriding the sandbox adapter in test env.
