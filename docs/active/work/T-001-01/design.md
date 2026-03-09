# T-001-01 Design: Scaffold Phoenix

## Decision 1: How to Run `mix phx.new` in a Non-Empty Repo

### Options

**A. Generate in current directory with `mix phx.new . --app haul`**
- Pros: Simplest. Phoenix handles the merge, prompts for overwrites.
- Cons: Will attempt to overwrite .gitignore, README.md. Interactive prompts don't work in automated context.

**B. Generate in a temp directory, then copy files over**
- Pros: Full control over what goes where. No overwrite risk.
- Cons: More manual steps. Risk of missing a file.

**C. Generate in current directory with `--no-git --no-install`, then handle conflicts**
- Pros: Skips git init and dep install. We control the merge.
- Cons: Still overwrites .gitignore and README.md if they exist.

### Decision: Option B — Generate in temp, copy selectively

Generate `mix phx.new /tmp/haul --app haul --no-git --no-install` into a temp directory. Copy the Phoenix scaffolding (mix.exs, config/, lib/, test/, assets/, priv/, rel/) into the repo root. Keep our existing .gitignore, README.md, CLAUDE.md, docs/, etc. This gives clean control.

## Decision 2: HTTP Server

Phoenix 1.8 defaults to Bandit (pure Elixir HTTP server). Cowboy is the legacy option.

### Decision: Keep Bandit (default)

Bandit is the modern default, pure Elixir, good performance, and simpler dependency tree. No reason to switch to Cowboy.

## Decision 3: All Ash Deps Now vs. Incremental

### Options

**A. Add all Ash deps listed in the ticket AC immediately**
- Pros: Matches acceptance criteria exactly. Future tickets can use any dep without waiting.
- Cons: Larger initial compile. Some deps (ash_double_entry, ash_oban) need config that doesn't exist yet.

**B. Add only ash, ash_postgres, ash_phoenix now; add others incrementally**
- Pros: Smaller footprint. Only compile what's needed.
- Cons: Violates ticket AC which explicitly lists all deps.

### Decision: Option A — Add all deps now

The ticket AC explicitly lists all deps. Adding them now with `only: :test` where appropriate ensures the compile succeeds. Deps that need runtime config (ash_oban needs Oban config) can have minimal config or be deferred — but they should be in mix.exs.

## Decision 4: Formatter Configuration for Ash

Ash DSL modules require their imports listed in `.formatter.exs` so `mix format` doesn't mangle DSL blocks. The standard pattern:

```elixir
[
  import_deps: [
    :ash, :ash_postgres, :ash_phoenix, :ash_authentication,
    :ash_state_machine, :ash_oban, :ash_double_entry,
    :ash_money, :ash_paper_trail, :ash_archival, :phoenix
  ],
  ...
]
```

### Decision: Configure all Ash imports upfront

Even though no Ash resources exist yet, having the formatter configured means the first resource file will format correctly without a separate ticket.

## Decision 5: Credo Configuration

### Decision: Generate `.credo.exs` with `mix credo gen.config`, then set strict: true

Credo's generated config is a good starting point. Set `strict: true` to match CI expectations (`mix credo --strict`).

## Decision 6: Database Configuration

No database resources exist yet, but Ecto/Repo should be configured for Postgres. Dev config points to local Postgres, test config uses a sandbox. The spec mentions Neon for production (configured via DATABASE_URL in runtime.exs).

### Decision: Keep Phoenix defaults for dev/test, add Neon-compatible runtime.exs

Standard Phoenix Postgres config for dev/test. Runtime.exs reads DATABASE_URL and configures SSL for Neon.

## Rejected Alternatives

- **Umbrella project**: Spec explicitly says no umbrella. Single mix.exs.
- **Node.js for assets**: Spec says no node_modules. Phoenix built-in esbuild + tailwind.
- **Custom project structure**: Follow Phoenix conventions exactly, then Ash domain directories come in later tickets.
