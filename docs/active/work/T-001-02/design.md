# T-001-02 Design — Version Pinning

## Decision: Use `mise.toml` (not `.tool-versions`)

### Options considered

#### Option A: `.tool-versions` (asdf-compatible)

```
erlang 28.3
elixir 1.19.5-otp-28
```

Pros:
- Universal: works with asdf, mise, rtx, and any `.tool-versions`-aware tool.
- Familiar to most Elixir devs.

Cons:
- No comments, no per-environment overrides.
- Elixir version format for asdf/mise requires the `-otp-XX` suffix, which is fragile and non-obvious.
- Does not support mise-specific features (env vars, tasks, hooks).

#### Option B: `mise.toml` (mise native)

```toml
[tools]
erlang = "28"
elixir = "1.19"
```

Pros:
- Native mise format — the project already uses mise.
- Supports comments, sections, env vars (expandable later).
- Cleaner syntax for Elixir+OTP pairing.
- Minor-level pinning (`"28"`, `"1.19"`) is natural — mise resolves to latest patch.

Cons:
- Only works with mise, not asdf. (Not a concern — project standardizes on mise.)

#### Option C: Both files

Maintain both `.tool-versions` and `mise.toml` for maximum compatibility.

Rejected: duplication with no benefit. The project uses mise exclusively.

### Decision: Option B — `mise.toml`

Rationale:
1. Project already standardizes on mise (CONTRIBUTING.md, `.just/system.just`).
2. Native format is cleaner and supports future expansion.
3. Minor-level pinning aligns with AC ("1.19.x and OTP 28.x").

## Pin level: Minor (not patch)

The AC explicitly says "Elixir 1.19.x and Erlang/OTP 28.x". We pin at minor level:
- `erlang = "28"` → mise installs latest 28.x patch
- `elixir = "1.19"` → mise installs latest 1.19.x patch

This matches CI behavior (`erlef/setup-beam` with `"1.19"` and `"28"`).

## mix.exs constraint tightening

Current: `elixir: "~> 1.15"` — allows 1.15 through 1.x, far too loose.

New: `elixir: "~> 1.19"` — requires 1.19.x minimum, rejects 1.18 or 2.0.

This ensures `mix deps.get` fails fast if someone runs on an old Elixir.

## CI alignment strategy

CI already uses env vars `ELIXIR_VERSION: "1.19"` and `OTP_VERSION: "28"`. These are consistent with our mise.toml pins. We will **not** add mise to CI — `erlef/setup-beam` is faster and purpose-built for GitHub Actions. The versions just need to stay in sync.

To make the single-source-of-truth relationship clear, we'll add a comment in `ci.yml` referencing `mise.toml`.

## Dockerfile note

No Dockerfile exists yet. When one is created (T-001-01 or later), it should use the same Elixir/OTP versions. We'll add a comment in `mise.toml` noting that Dockerfile versions must match. The Dockerfile will use `hexpm/elixir:1.19.x-erlang-28.x-*` base images with ARGs.

## What was rejected

- **Exact patch pinning** (e.g., `1.19.5`): Too brittle for a small team. Minor-level is sufficient — security patches auto-apply.
- **Reading versions from mise.toml in CI**: Over-engineering. Versions change maybe once a year. A comment linking the two is enough.
- **asdf compatibility**: Project uses mise; no one is using asdf.
