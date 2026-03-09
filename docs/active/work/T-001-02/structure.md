# T-001-02 Structure — Version Pinning

## Files to create

### `mise.toml` (repo root)

```toml
# Version pins — keep in sync with:
#   .github/workflows/ci.yml (ELIXIR_VERSION, OTP_VERSION)
#   Dockerfile ARGs (when created)

[tools]
erlang = "28"
elixir = "1.19"
```

Purpose: Single source of truth for local dev versions. `mise install` reads this.

## Files to modify

### `mix.exs`

Change `elixir: "~> 1.15"` → `elixir: "~> 1.19"` in `project/0`.

This is a one-line change in the project keyword list.

### `.github/workflows/ci.yml`

Add a comment to the `env:` block linking to `mise.toml`:

```yaml
env:
  MIX_ENV: test
  # Keep in sync with mise.toml
  ELIXIR_VERSION: "1.19"
  OTP_VERSION: "28"
```

No version values change — they already match. Just add the sync comment.

## Files NOT modified

- **Dockerfile**: Doesn't exist yet. Future ticket responsibility.
- **CONTRIBUTING.md**: Already says `mise install` — no change needed.
- **`.just/system.just`**: Already mentions Elixir 1.19 in prose — no change needed.
- **`justfile`**: No version references.

## Module boundaries

N/A — this ticket is config-only, no Elixir modules involved.

## Ordering

1. Create `mise.toml` first (it's the source of truth).
2. Update `mix.exs` (tighten constraint).
3. Update `ci.yml` (add comment).

Order matters only loosely — all three are independent files. But conceptually the version pin file comes first.

## Verification

- `mise install` in repo root installs correct Elixir/OTP versions.
- `elixir --version` shows 1.19.x on OTP 28.
- `mix deps.get` succeeds (mix.exs constraint satisfied).
- CI workflow still works (no version value changes, just comment added).
