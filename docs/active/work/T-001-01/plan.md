# T-001-01 Plan: Scaffold Phoenix

## Step 1: Generate Phoenix Project in Temp Directory

```bash
mix phx.new /tmp/haul --app haul --module Haul --no-git --no-install
```

This creates a clean Phoenix 1.8 scaffold without initializing git or running `mix deps.get`.

**Verify**: Directory exists with expected files.

## Step 2: Copy Generated Files to Repo Root

Copy these directories/files from `/tmp/haul/` to the repo root:
- `mix.exs`
- `config/`
- `lib/`
- `test/`
- `assets/`
- `priv/`
- `rel/` (if generated — release config)
- `.formatter.exs`

Do NOT copy:
- `.gitignore` (repo already has one)
- `README.md` (repo already has one)
- `.git/` (doesn't exist, we used --no-git)

**Verify**: `ls` shows expected directory structure.

## Step 3: Add Ash Deps to mix.exs

Edit `mix.exs` to add all Ash ecosystem deps after the Phoenix defaults:
- ash, ash_postgres, ash_phoenix, ash_authentication
- ash_state_machine, ash_oban, ash_double_entry
- ash_money, ash_paper_trail, ash_archival

Add quality/test deps:
- credo (dev/test, runtime: false)
- dialyxir (dev/test, runtime: false)
- ex_machina (test only)

**Verify**: `mix.exs` contains all listed deps.

## Step 4: Configure .formatter.exs for Ash

Edit `.formatter.exs` to add `import_deps` for all Ash packages plus `:phoenix`:

```elixir
import_deps: [:ash, :ash_postgres, :ash_phoenix, :ash_authentication,
              :ash_state_machine, :ash_oban, :ash_double_entry,
              :ash_money, :ash_paper_trail, :ash_archival,
              :ecto, :ecto_sql, :phoenix]
```

**Verify**: File parses correctly.

## Step 5: Install Deps and Compile

```bash
mix deps.get
mix compile
```

**Verify**: Both commands exit 0. Compilation produces zero warnings.

If warnings exist, fix them (usually config adjustments) before proceeding.

## Step 6: Generate .credo.exs

```bash
mix credo gen.config
```

Then verify it exists and has strict defaults. Credo's generated config has `strict: false` by default — but we run `mix credo --strict` in CI which overrides it via CLI flag, so the config file itself doesn't need modification.

**Verify**: `.credo.exs` exists and `mix credo --strict` returns 0.

## Step 7: Run Format Check

```bash
mix format
mix format --check-formatted
```

**Verify**: All files formatted correctly, including Ash DSL compatibility.

## Step 8: Run Tests

```bash
mix test
```

**Verify**: Default Phoenix tests pass (page controller, error views).

## Step 9: Verify Full CI Pipeline Locally

```bash
mix compile --warnings-as-errors
mix format --check-formatted
mix credo --strict
mix test
```

**Verify**: All four commands pass. This matches what CI will run.

## Step 10: Verify .gitignore Coverage

Ensure the existing `.gitignore` covers all Phoenix patterns. Compare against what `mix phx.new` would generate. Add any missing patterns.

**Verify**: `git status` shows only intended new files, not build artifacts.

## Testing Strategy

- **No new tests to write**: This is scaffolding. The Phoenix generator includes default tests (page controller, error views). Those should pass.
- **CI validation**: The acceptance criteria include `mix deps.get && mix compile` succeeding with zero warnings. This is verified in Steps 5 and 9.
- **Smoke test**: After Step 8, the app should be startable with `mix phx.server` (manual verification, not automated).

## Commit Strategy

Single commit: "Scaffold Phoenix 1.8 app with Ash ecosystem deps"

All generated + modified files in one atomic commit since the project doesn't compile without all pieces present.
