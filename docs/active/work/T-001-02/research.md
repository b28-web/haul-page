# T-001-02 Research — Version Pinning

## Objective

Pin Elixir and Erlang/OTP versions so local dev, CI, and Docker builds all use the same versions.

## Current state

### Versions in use

The system currently runs **Elixir 1.19.5** on **Erlang/OTP 28** (confirmed via `elixir --version`).

### Where versions are referenced today

| Location | Elixir | OTP | Format |
|----------|--------|-----|--------|
| `.github/workflows/ci.yml` env block | `"1.19"` | `"28"` | Minor-only strings, consumed by `erlef/setup-beam@v1` |
| `mix.exs` project/0 | `"~> 1.15"` | — | Loose minimum, allows anything ≥1.15 |
| `CONTRIBUTING.md` | "Elixir 1.19 + Erlang/OTP 28" | — | Prose |
| `.just/system.just` `_llm` recipe | "Elixir 1.19" | — | Prose in agent briefing |
| Dockerfile | **Does not exist yet** | — | T-001-01 dep hasn't produced one |

### Version management tooling

- **mise** is installed (`2026.3.5 macos-arm64`) and referenced in CONTRIBUTING.md (`mise install`).
- No `.tool-versions` or `mise.toml` exists at the repo root.
- `mise` supports both `.tool-versions` (asdf-compatible) and `mise.toml` (native) formats.

### CI version resolution

CI uses `erlef/setup-beam@v1` which accepts:
- Major.minor (e.g., `"1.19"`) → latest patch of that minor
- Major.minor.patch (e.g., `"1.19.5"`) → exact patch
- Current values are minor-only: `ELIXIR_VERSION: "1.19"`, `OTP_VERSION: "28"`.

### Dockerfile status

No Dockerfile exists at the repo root. T-001-01 (scaffold-phoenix) is the dependency and is still in-progress. Phoenix ships a Dockerfile template at `deps/phoenix/priv/templates/phx.gen.release/Dockerfile.eex` which uses `hexpm/elixir` base images with version ARGs.

### mix.exs constraint

`mix.exs` specifies `elixir: "~> 1.15"` which is extremely loose — any 1.x ≥ 1.15 would satisfy. This should be tightened to match the pinned version.

## Constraints and boundaries

1. **No Dockerfile yet.** We can create the version-pinning files and update CI, but Dockerfile alignment will need to happen when the Dockerfile is created (likely T-001-01 or a later infra ticket).
2. **mise is the expected tool.** CONTRIBUTING.md already tells devs to run `mise install`. We need to provide the config file it reads.
3. **CI uses `erlef/setup-beam`**, not mise. Versions need to be consistent but the mechanisms differ.
4. **Patch-level vs minor-level pinning.** The ticket says "1.19.x and OTP 28.x" — this implies minor-level pinning (latest patch OK), not exact patch pinning.

## Files involved

| File | Action needed |
|------|---------------|
| `.tool-versions` or `mise.toml` | **Create** — pin Elixir + Erlang |
| `.github/workflows/ci.yml` | **Verify** — already pins at minor level, may need to read from version file |
| `mix.exs` | **Update** — tighten `elixir:` constraint |
| Dockerfile | **N/A** — doesn't exist yet, will be addressed by future ticket |

## Assumptions

- Patch-level float is acceptable (AC says "1.19.x" not "1.19.5").
- `mise.toml` is preferred over `.tool-versions` since the project uses mise natively.
- CI doesn't need to parse the mise config — keeping the versions in sync manually is acceptable since they change rarely.
