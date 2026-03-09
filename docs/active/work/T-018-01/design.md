# T-018-01 Design: BAML Dependency Setup

## Decision: Use baml_elixir NIF with REST sidecar fallback documented

### Options evaluated

#### Option A: baml_elixir NIF (Rustler)
- **Pro**: Native Elixir integration, no sidecar process, typed client generated from `.baml` files
- **Pro**: Matches ticket's explicit requirement ("add `baml_elixir` to deps")
- **Con**: Pre-release package (1.0.0-pre.13), community-maintained
- **Con**: Requires Rust toolchain in dev, CI, and Docker
- **Con**: NIF compilation adds build complexity and time

#### Option B: BAML REST sidecar (`baml-cli serve`)
- **Pro**: Official BoundaryML approach for unsupported languages
- **Pro**: No Rust compilation in Elixir build
- **Con**: Separate process to manage (Docker Compose or multi-process)
- **Con**: HTTP overhead, deployment complexity
- **Con**: Not what the ticket asks for

#### Option C: InstructorLite (pure Elixir)
- **Pro**: No BAML at all, pure Elixir, Ecto-style schemas
- **Pro**: Zero build complexity
- **Con**: Not BAML — downstream tickets (T-018-02, 03, 04) expect BAML functions
- **Con**: Different paradigm, would require re-scoping the entire E-011 epic

#### Option D: Direct HTTP to Anthropic API
- **Pro**: Simplest, no dependencies
- **Con**: No structured output parsing, no retry logic, no type safety
- **Con**: Not BAML — would invalidate downstream tickets

### Chosen: Option A (baml_elixir NIF)

**Rationale**: The ticket explicitly requires `baml_elixir`. The entire E-011 epic (AI onboarding) is built around BAML's structured extraction. The NIF approach keeps everything in-process. If compilation fails on any platform, the ticket's acceptance criteria say to document the issue and evaluate the REST sidecar fallback.

**Risk mitigation**:
- Pin to `~> 0.2.0` (stable) first; try pre-release only if stable doesn't work
- Test compilation on macOS ARM64 immediately
- If NIF fails, document and pivot to Option B

### Adapter pattern for LLM calls

Follow the existing project pattern (like payments, SMS, places):
- `Haul.AI` behaviour with `call_function/3` (function name, params, opts)
- `Haul.AI.Baml` — real adapter using `BamlElixir.Client`
- `Haul.AI.Sandbox` — dev/test adapter returning fixture responses
- Config: `config :haul, :ai_adapter, Haul.AI.Sandbox`
- Runtime: switch to `Haul.AI.Baml` when `ANTHROPIC_API_KEY` is set

### BAML file organization
- `baml/` at project root (standard BAML convention)
- Start with one trivial function for the smoke test
- Downstream tickets will add extraction functions here

### Smoke test strategy
- Define a trivial BAML function (e.g., `ExtractName` that pulls a name from text)
- Test uses the Sandbox adapter — no real API calls
- Verifies the BAML compilation pipeline works and types are available in Elixir
- Separate integration test (tagged `@tag :external`) for real API calls (skipped in CI)

### ANTHROPIC_API_KEY configuration
- Add to `runtime.exs` in prod block (like other API keys)
- No key needed in dev/test (sandbox adapter)
- Document in acceptance criteria

### Dockerfile changes
- Add `curl` + Rust toolchain install to builder stage
- Use `rustup` for minimal install
- Rust only needed in builder, not runtime stage
- Consider Rustler precompiled binaries to skip Rust in Docker if available

### CI changes
- Add `dtolnay/rust-toolchain@stable` step before `mix deps.get`
- Only needed in test and quality jobs (not deploy — that uses Docker)

### What was rejected
- **InstructorLite**: Would require re-architecting E-011. BAML is the spec'd approach.
- **REST sidecar as primary**: Over-engineered for this stage. Try NIF first.
- **Direct HTTP**: No structured output, defeats the purpose of BAML.
- **Pre-release version**: Start with stable 0.2.0 for lower risk.
