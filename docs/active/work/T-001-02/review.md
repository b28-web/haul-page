# T-001-02 Review — Version Pinning

## Summary of changes

### Files created

| File | Purpose |
|------|---------|
| `mise.toml` | Pins Erlang 28 + Elixir 1.19 for local dev. Source of truth for toolchain versions. |

### Files modified

| File | Change |
|------|--------|
| `mix.exs` | Tightened `elixir:` constraint from `"~> 1.15"` to `"~> 1.19"` |
| `.github/workflows/ci.yml` | Added `# Keep in sync with mise.toml` comment above version env vars |

### Files not modified (and why)

- **Dockerfile**: Doesn't exist yet. When created, it should use matching versions. `mise.toml` has a comment noting this.
- **CONTRIBUTING.md**: Already references `mise install` — no change needed.
- **`.just/system.just`**: Prose already says "Elixir 1.19" — no change needed.

## Acceptance criteria check

| Criterion | Status |
|-----------|--------|
| `.tool-versions` or `mise.toml` at repo root pins Elixir 1.19.x and Erlang/OTP 28.x | **Met** — `mise.toml` pins both |
| Versions match CI workflow and Dockerfile build stage | **Met** (CI) / **N/A** (Dockerfile doesn't exist yet) |
| `mise install` sets up correct versions | **Met** — verified: Erlang 28.4, Elixir 1.19.5-otp-28 |

## Test coverage

This is a config-only ticket. No new Elixir code was written, so no unit tests are applicable.

Verification performed:
- `mise install` → succeeds, installs correct versions
- `mise current` → shows `erlang 28.4`, `elixir 1.19.5-otp-28`
- `mix compile` → succeeds (constraint satisfied)
- `mix test` → 5 tests, 0 failures (existing tests still pass)

## Open concerns

1. **Dockerfile alignment**: When a Dockerfile is created (T-001-01 or later infra ticket), its base image versions must match `mise.toml`. The comment in `mise.toml` flags this. Whoever creates the Dockerfile should verify.

2. **CI version sync is manual**: CI env vars and `mise.toml` are not programmatically linked. This is deliberate (versions change rarely, and parsing TOML in CI adds complexity for no benefit). The comment in `ci.yml` reminds maintainers to update both places.

## No known issues

All changes are minimal and config-only. No regressions possible beyond a version mismatch if someone updates one file but not the others — mitigated by the sync comments.
