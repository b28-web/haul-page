# T-018-01 Plan: BAML Dependency Setup

## Step 1: Add baml_elixir dependency and verify compilation

1. Add `{:baml_elixir, "~> 0.2.0"}` to `mix.exs` deps
2. Run `mix deps.get`
3. Run `mix compile` — verify NIF compiles on macOS ARM64
4. If compilation fails: try pre-release version, document issues
5. **Verify**: `mix compile` succeeds with no errors

## Step 2: Create baml/ directory with minimal BAML source

1. Create `baml/` directory at project root
2. Create `baml/main.baml` with:
   - Anthropic client configuration
   - One trivial function `ExtractName(text: string) -> Name`
   - `Name` type with `first_name` and `last_name` fields
3. **Verify**: BAML source is syntactically valid

## Step 3: Create AI adapter modules

1. Create `lib/haul/ai.ex` — behaviour + public API
   - `@callback call_function(String.t(), map(), keyword()) :: {:ok, any()} | {:error, any()}`
   - `def call_function(name, params, opts \\ [])` delegates to configured adapter
2. Create `lib/haul/ai/sandbox.ex` — returns fixture responses
   - Pattern-match on function name for different fixture responses
   - Default: `{:ok, %{"result" => "sandbox"}}`
3. Create `lib/haul/ai/baml.ex` — wraps BamlElixir
   - Calls `BamlElixir.Client.call/2` (or equivalent API)
   - Handles errors, wraps in `{:ok, _} | {:error, _}`
4. **Verify**: modules compile

## Step 4: Add configuration

1. `config/config.exs`: add `config :haul, :ai_adapter, Haul.AI.Sandbox`
2. `config/test.exs`: add `config :haul, :ai_adapter, Haul.AI.Sandbox`
3. `config/runtime.exs`: add ANTHROPIC_API_KEY block
   ```elixir
   if anthropic_key = System.get_env("ANTHROPIC_API_KEY") do
     config :haul, :ai_adapter, Haul.AI.Baml
     config :haul, :anthropic_api_key, anthropic_key
   end
   ```
4. **Verify**: `mix compile` still clean

## Step 5: Write smoke test

1. Create `test/haul/ai_test.exs`
   - Test `Haul.AI.call_function/3` with sandbox adapter
   - Verify returns `{:ok, _}` tuple
   - Verify fixture response structure
2. Run `mix test test/haul/ai_test.exs`
3. **Verify**: test passes

## Step 6: Update Dockerfile

1. Add Rust installation to builder stage (after apt-get, before mix deps):
   ```dockerfile
   RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
   ENV PATH="/root/.cargo/bin:${PATH}"
   ```
2. **Verify**: `docker build` succeeds (test locally if possible)

## Step 7: Update CI workflow

1. Add Rust toolchain step to `test` job (before `mix deps.get`):
   ```yaml
   - uses: dtolnay/rust-toolchain@stable
   ```
2. Add same step to `quality` job
3. **Verify**: CI config is valid YAML

## Step 8: Run full test suite

1. Run `mix test` — all existing tests still pass
2. Run `mix format --check-formatted`
3. Run `mix compile --warnings-as-errors`
4. **Verify**: no regressions

## Testing strategy
- **Unit test**: `test/haul/ai_test.exs` — sandbox adapter smoke test
- **No integration test in CI**: real API calls require key, not available in CI
- **Manual verification**: `mix compile` with NIF on macOS ARM64
- **Docker verification**: build succeeds with Rust in builder stage
