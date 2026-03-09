# T-001-01 Progress: Scaffold Phoenix

## Completed Steps

### Step 1: Generate Phoenix Project ✓
- Ran `mix phx.new /tmp/haul --app haul --module Haul --no-install`
- Phoenix 1.8.5 generated successfully

### Step 2: Copy to Repo Root ✓
- Copied mix.exs, config/, lib/, test/, assets/, priv/, .formatter.exs
- Preserved existing .gitignore, README.md, CLAUDE.md, docs/

### Step 3: Add Ash Deps ✓
- Added all 10 Ash ecosystem deps to mix.exs
- Added credo, dialyxir, ex_machina

### Step 4: Configure .formatter.exs ✓
- Added import_deps for all Ash packages

### Step 5: Install Deps and Compile ✓
- `mix deps.get` resolved 90+ packages
- `mix compile` succeeded
- `mix compile --warnings-as-errors` passes (zero warnings in haul app)

### Step 6: Generate .credo.exs ✓
- `mix credo gen.config` created .credo.exs
- Fixed 4 credo issues in generated code:
  - Reordered alias in lib/haul_web.ex (alphabetical)
  - Added `alias Phoenix.HTML.Form` in core_components.ex
  - Aliased `Ecto.Adapters.SQL.Sandbox` in data_case.ex

### Step 7: Create Haul.Cldr Backend (Deviation)
- ex_money requires a CLDR backend at startup
- Created lib/haul/cldr.ex with English locale and Money provider
- Added config for ex_money default_cldr_backend in config.exs

### Step 8: Full CI Verification ✓
- `mix compile --warnings-as-errors` — PASS
- `mix format --check-formatted` — PASS
- `mix credo --strict` — PASS (0 issues)
- `mix test` — PASS (5 tests, 0 failures)

### Step 9: Verify .gitignore ✓
- Existing .gitignore covers all Phoenix patterns
- No additions needed

## Deviations from Plan

1. **CLDR backend required** — ex_money (dep of ash_money) requires a configured CLDR backend. Added `Haul.Cldr` module and config. This was not anticipated in the plan but is a direct consequence of adding ash_money as a dep.

2. **Docker for Postgres** — Local Postgres was not running. Started a Docker container (postgres:16) for test database. This is infrastructure, not code.

## Remaining

Nothing — all implementation steps complete.
