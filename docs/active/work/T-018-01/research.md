# T-018-01 Research: BAML Dependency Setup

## What exists

### Project stack
- Elixir 1.19 / OTP 28 on macOS ARM64 (dev) and Debian Bookworm x86_64 (Docker/CI)
- Phoenix 1.8.5 + Ash 3.19 + LiveView 1.1
- Dependencies managed via `mix.exs`, pinned versions in `mise.toml`
- Multi-stage Dockerfile: deps → build → runtime (Debian slim)
- CI: GitHub Actions with `erlef/setup-beam@v1`, no Rust toolchain installed
- Config pattern: adapter-based (sandbox for dev/test, real for prod via env vars in `runtime.exs`)

### Relevant config files
- `mix.exs` — deps list, aliases, compilers
- `config/config.exs` — ash_domains, adapters, esbuild/tailwind
- `config/runtime.exs` — env-var-driven prod config (Stripe, Twilio, Sentry, etc.)
- `config/test.exs` — sandbox adapters, Oban manual mode
- `Dockerfile` — multi-stage build, no Rust toolchain
- `.github/workflows/ci.yml` — test + quality + guardrails + deploy jobs
- `mise.toml` — Erlang 28, Elixir 1.19 (no Rust)

### Existing patterns for external services
Every external service follows the same adapter pattern:
1. Define a behaviour module (e.g., `Haul.Payments`, `Haul.SMS`)
2. Implement `Sandbox` adapter for dev/test (returns canned responses)
3. Implement real adapter for prod (e.g., `Haul.Payments.Stripe`)
4. Config key selects adapter: `config :haul, :payments_adapter, ...`
5. Runtime.exs switches to real adapter when env vars are present

### No existing AI/LLM integration
No LLM client, no BAML, no structured output tooling exists yet.

## BAML ecosystem

### What is BAML
BAML (Boundary AI Markup Language) is a DSL for structured LLM output. You define functions in `.baml` files with typed inputs/outputs, BAML compiles to native client code that calls LLM APIs and parses responses into typed data. Supports OpenAI, Anthropic, Gemini, etc.

### baml_elixir package
- **Exists on hex.pm**: `baml_elixir`
- **Versions**: stable `0.2.0`, pre-release `1.0.0-pre.13`
- **Author**: Emil Soman (community, not official BoundaryML)
- **Implementation**: Rust NIF via Rustler — wraps BAML's Rust core
- **Requirements**: Rust toolchain needed at compile time
- **API**: `BamlElixir.Client` with `call/2` and `stream/3`
- **GitHub**: `emilsoman/baml_elixir`

### NIF compilation implications
- **Dev (macOS ARM64)**: needs Rust installed via `rustup`
- **Docker (Debian x86_64)**: needs `curl`, `rustup` or `apt install rustc` in builder stage
- **CI (ubuntu-latest)**: needs Rust toolchain added to workflow
- Pre-compiled NIF binaries may be available (Rustler precompiled), but unclear for baml_elixir
- Adds ~2-3 min to cold Docker builds, cached afterward

### Official BAML language support
Python, TypeScript, Ruby, Java, C#, Rust, Go. **No official Elixir client.**

### Alternative approaches
1. **baml_elixir NIF** — community package, pre-release, Rust compilation required
2. **BAML REST server** (`baml-cli serve`) — official sidecar, exposes BAML functions as HTTP endpoints
3. **InstructorLite** — pure Elixir structured output library, Ecto-style schemas, no BAML
4. **Direct HTTP** — call Anthropic/OpenAI APIs directly with `Req`, parse JSON manually

## Constraints and assumptions
- Ticket says "add `baml_elixir`" — implies NIF approach is the primary target
- Acceptance criteria require `baml/` directory, `.baml` source files, smoke test
- Fallback to REST sidecar is explicitly mentioned if NIF fails
- `ANTHROPIC_API_KEY` env var config is required regardless of approach
- Downstream tickets (T-018-02, 03, 04) depend on BAML being available for structured extraction
- The smoke test should work with a fixture/mock — no real API calls in CI

## Key files to modify
- `mix.exs` — add `baml_elixir` dep
- `mise.toml` — possibly add Rust toolchain
- `config/config.exs` — BAML/LLM adapter config
- `config/runtime.exs` — `ANTHROPIC_API_KEY` env var
- `config/test.exs` — sandbox/mock config for LLM calls
- `Dockerfile` — add Rust to builder stage
- `.github/workflows/ci.yml` — add Rust toolchain step
- New: `baml/` directory with `.baml` source files
- New: smoke test file
