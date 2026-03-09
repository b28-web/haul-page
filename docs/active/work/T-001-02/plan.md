# T-001-02 Plan — Version Pinning

## Steps

### Step 1: Create `mise.toml`

Create `mise.toml` at the repo root with Erlang 28 and Elixir 1.19 pins.

Verification: `cat mise.toml` shows correct content.

### Step 2: Verify `mise install` works

Run `mise install` in the repo root. Confirm it resolves to Elixir 1.19.x and OTP 28.x.

Verification: `mise current` or `elixir --version` shows expected versions.

### Step 3: Update `mix.exs` elixir constraint

Change `elixir: "~> 1.15"` to `elixir: "~> 1.19"` in `project/0`.

Verification: `mix compile` succeeds (constraint satisfied by current Elixir).

### Step 4: Add sync comment to CI workflow

Add `# Keep in sync with mise.toml` comment above the version env vars in `.github/workflows/ci.yml`.

Verification: Visual inspection of the diff.

### Step 5: Run existing tests

Run `mix test` to confirm nothing is broken by the mix.exs constraint change.

Verification: All tests pass.

## Testing strategy

This ticket is config-only. There are no unit or integration tests to write.

Verification is:
1. `mise install` works and installs correct versions.
2. `mix compile` succeeds with the tightened constraint.
3. `mix test` passes.
4. CI workflow file is syntactically valid (no YAML errors).

## Commit plan

Single atomic commit containing:
- New `mise.toml`
- Updated `mix.exs`
- Updated `.github/workflows/ci.yml`

These three changes are logically one unit: "pin Elixir/OTP versions."
