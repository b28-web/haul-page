# T-001-06 Design: mix setup

## Problem

`mix setup` exists but seeds are empty. The acceptance criteria require realistic dev seed data and end-to-end verification that the alias chain works from a clean clone.

## Option A: Full operator seed with config values (chosen)

Write seeds that read the `:operator` config and log it, confirming the operator identity is loaded. Add a `seeds_dev.exs` helper that's only run in dev, keeping `seeds.exs` environment-agnostic.

**Pros:** Works now without Ash resources. Seeds demonstrate that config is loaded correctly. When T-004-01 adds Company/User resources, we extend seeds rather than rewrite.
**Cons:** Seeds are minimal until domain resources exist.

## Option B: Stub seeds with TODO comments only

Leave seeds as-is with comments marking where data will go.

**Rejected:** Doesn't satisfy "Dev seeds create a sample operator with realistic data." Even without DB resources, we should demonstrate that config-driven operator data is populated and accessible.

## Option C: Create fake Ecto schemas for seeding

Create temporary schemas just to have something to seed.

**Rejected:** Creates throwaway code. Ash resources (T-004-01) will replace these. Wasted work.

## Design decisions

### 1. Seeds approach

`priv/repo/seeds.exs` will:
- Be idempotent (safe to run multiple times)
- Log the operator identity as confirmation
- Include a clearly marked section for future Ash resource seeds
- Use `Mix.env()` guard for dev-only seed data

### 2. Setup alias adjustment

Current alias is correct. One addition: add `deps.compile` explicitly before `ecto.setup` for clarity and to satisfy the AC literally. The sequence becomes:
```elixir
setup: ["deps.get", "deps.compile", "ecto.setup", "assets.setup", "assets.build"]
```

Actually, on reflection: `deps.compile` is redundant — `ecto.create` and `compile` (in assets.build) both trigger compilation. Adding it explicitly just adds time. The AC says "runs: deps.get, deps.compile, db create, db migrate, seeds, assets setup" — this is a description of what should happen, not a literal alias list. The current alias achieves all of those effects. Keep as-is.

### 3. Verification

Add a `mix setup.verify` alias or just document that `mix phx.server` after `mix setup` is the verification. Since AC says "mix phx.server starts successfully after mix setup", that's the test. No new alias needed.

### 4. Seeds content

Since operator data lives in config (not DB), the seed file will:
1. Log the loaded operator config to confirm it's accessible
2. Print a summary of the dev environment state
3. Include a placeholder section for when Ash resources are added

This satisfies "realistic data" — the operator config in `config.exs` already has realistic defaults (business name, phone, services list).

## Testing strategy

- Run `mix setup` end-to-end in CI (already covered by test alias which runs ecto.create + migrate)
- Add a test that verifies operator config is loaded with expected keys
- Verify `mix phx.server` starts (manual verification, documented)
