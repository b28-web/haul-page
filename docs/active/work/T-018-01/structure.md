# T-018-01 Structure: BAML Dependency Setup

## Files to modify

### mix.exs
- Add `{:baml_elixir, "~> 0.2.0"}` to deps list (after Stripe section)
- No new compilers needed (Rustler handles NIF compilation automatically)

### mise.toml
- Add `rust = "latest"` to `[tools]` section (so dev machines get Rust via mise)

### config/config.exs
- Add AI adapter config: `config :haul, :ai_adapter, Haul.AI.Sandbox`
- Add `Haul.AI` to ash_domains list? No — AI is not an Ash domain, it's a service adapter

### config/runtime.exs
- Add `ANTHROPIC_API_KEY` env var handling (similar to GOOGLE_PLACES_API_KEY pattern)
- When set: `config :haul, :ai_adapter, Haul.AI.Baml`
- Pass key to BAML config: `config :haul, :anthropic_api_key, key`

### config/test.exs
- Add `config :haul, :ai_adapter, Haul.AI.Sandbox`
- Explicit sandbox for test env

### Dockerfile
- In builder stage: add `curl` to apt-get install list (already has `build-essential git`)
- Add RUN step to install Rust via rustup (after apt-get, before mix deps)
- Runtime stage: no changes (NIF binary is included in release)

### .github/workflows/ci.yml
- Add `dtolnay/rust-toolchain@stable` step in both `test` and `quality` jobs
- Place before `mix deps.get` step

## Files to create

### lib/haul/ai.ex
- Behaviour module defining `@callback call_function(String.t(), map(), keyword()) :: {:ok, any()} | {:error, any()}`
- Public `call_function/3` that delegates to configured adapter
- Pattern: same as `Haul.Payments`, `Haul.SMS`

### lib/haul/ai/sandbox.ex
- Implements `Haul.AI` behaviour
- Returns canned responses based on function name
- Used in dev/test

### lib/haul/ai/baml.ex
- Implements `Haul.AI` behaviour
- Wraps `BamlElixir.Client.call/2`
- Reads `ANTHROPIC_API_KEY` from config
- Used in prod when env var is set

### baml/main.baml
- Minimal BAML source file
- Define one trivial function: `ExtractName` — takes text, returns `{first_name, last_name}`
- Configures Anthropic as the LLM provider
- This is the `.baml` source that BAML compiles into client code

### test/haul/ai_test.exs
- Smoke test using Sandbox adapter
- Verifies `Haul.AI.call_function/3` returns expected structure
- No real API calls

## Module boundaries

```
Haul.AI (behaviour + delegator)
├── Haul.AI.Sandbox (test/dev adapter)
└── Haul.AI.Baml (prod adapter, wraps BamlElixir)

baml/
└── main.baml (BAML source files — compiled by baml_elixir NIF)
```

## Ordering
1. Add dep to mix.exs, run deps.get
2. Verify compilation on macOS ARM64
3. Create baml/ directory with main.baml
4. Create adapter modules (behaviour → sandbox → baml)
5. Add config entries
6. Write smoke test
7. Update Dockerfile
8. Update CI workflow
