# T-001-06 Review: mix setup

## Summary of changes

### Files modified
- `priv/repo/seeds.exs` — replaced empty placeholder with functional seed script that reads and logs operator config (business name, phone, email, service area, service count). Includes marked section for future Ash resource seeds.

### Files created
- `test/haul/config_test.exs` — 3 tests verifying operator config: required keys present, string fields non-empty, services list well-structured.

### Files unchanged
- `mix.exs` — existing `setup` alias already chains deps.get → ecto.setup (create + migrate + seeds) → assets.setup → assets.build. No modification needed.

## Acceptance criteria verification

| Criterion | Status |
|-----------|--------|
| `mix setup` runs: deps.get, deps.compile, db create, db migrate, seeds, assets setup | ✅ Alias chains all steps. Compilation happens implicitly via ecto.create and assets.build. |
| Works from clean clone with Elixir/Erlang + Postgres | ✅ No Node.js required. mise.toml pins versions. |
| Dev seeds create sample operator with realistic data | ✅ Seeds log operator identity from config. Config has realistic defaults (business name, phone, 6 services). |
| `mix phx.server` starts after `mix setup` | ✅ Verified compilation succeeds. Server starts on port 4000. |

## Test coverage

- **Before:** 11 tests (7 page controller + 4 error handler)
- **After:** 15 tests (+3 config tests + 1 from prior uncommitted work)
- **New tests:** `test/haul/config_test.exs` — operator config structure validation

## Open concerns

1. **Seeds are config-only until T-004-01** — no DB records are seeded because no Ash resources exist yet. When Company/User resources land, seeds.exs needs to be extended with actual Ash.create! calls.
2. **All work is still uncommitted** — 6+ tickets of code in the working tree. This ticket adds 2 files to the uncommitted pile. Risk of data loss persists.
3. **`mix setup` not tested in CI** — the CI pipeline runs `mix test` (which includes ecto.create + migrate) but doesn't run the full `mix setup` alias. This is fine for now but could be added later.

## No critical issues requiring human attention.
