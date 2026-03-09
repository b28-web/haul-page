# T-001-03 Research: CI Pipeline

## Current State

### Existing CI workflow (`.github/workflows/ci.yml`)

The file already exists (staged in git) with significant content beyond the ticket scope:

**Triggers:** push to `main`, PRs targeting `main`.

**Environment variables:**
```yaml
MIX_ENV: test
ELIXIR_VERSION: "1.19"
OTP_VERSION: "28"
```

**Jobs present:**

1. **test** — Postgres 16 service, `erlef/setup-beam@v1`, cache on `mix.lock` hash, `mix deps.get`, `mix compile --warnings-as-errors`, `mix test`. Matches AC fully.

2. **quality** — Same beam/cache setup. Runs `mix format --check-formatted`, `mix credo --strict`. **Missing: `mix dialyzer`** per AC. Also missing `mix compile` step before credo (credo needs compiled code for some checks).

3. **guardrails** — PR-only job. Checks diff size (800 line max), fixup/wip commits, debug leftovers, hardcoded secrets, missing test files. Not in AC — bonus job.

4. **deploy** — Fly.io deploy on main push via `superfly/flyctl-actions`. Depends on test + quality + guardrails. Ticket says "No deploy job yet" but one is already present.

### Version pinning

`mise.toml` pins Erlang 28 and Elixir 1.19. No `.tool-versions` file. CI env vars match these pins. Comment in `mise.toml` says "keep in sync with `.github/workflows/ci.yml`".

### Project dependencies relevant to quality jobs

- `credo ~> 1.7` — in deps, dev+test only. `.credo.exs` config exists.
- `dialyxir ~> 1.4` — in deps, dev+test only. No `.dialyzer_ignore.exs` yet.
- `mix format` — `.formatter.exs` exists with Ash/Phoenix plugin imports.

### Test infrastructure

- `config/test.exs` — Postgres configured with `postgres`/`postgres` creds on localhost, matches CI service definition.
- 3 test files exist: `error_html_test.exs`, `page_controller_test.exs`, `error_json_test.exs`.
- `mix.exs` aliases: `test` creates DB + migrates + runs tests.

### Caching

Both test and quality jobs cache `deps` and `_build` with key `mix-${{ runner.os }}-${{ hashFiles('mix.lock') }}` and fallback `mix-${{ runner.os }}-`. This matches AC.

## Gaps Against Acceptance Criteria

| AC | Status | Gap |
|----|--------|-----|
| `.github/workflows/ci.yml` exists | Met | — |
| test job: PG 16, deps.get, compile --warnings-as-errors, test | Met | — |
| quality job: format, credo --strict, dialyzer | Partial | **`mix dialyzer` missing** |
| erlef/setup-beam with pinned versions matching mise.toml | Met | Versions sync'd via env vars |
| Deps/_build cached by mix.lock hash | Met | — |
| Pipeline passes on clean push | Unknown | Need to verify or push |

## Observations

1. Quality job needs `mix compile` before `mix credo --strict` — credo needs compiled BEAM files for some checks.
2. Quality job is missing `mix dialyzer` entirely.
3. Dialyzer PLT build is expensive (~2-5 min). PLT should be cached separately from deps/build cache, keyed on OTP+Elixir version + mix.lock hash.
4. The deploy job exists but ticket says "No deploy job yet." It was likely added anticipatorily — keep it, it's not harmful and a later ticket (T-001-04/05/06) will need it.
5. The guardrails job is extra but useful — keep it.
6. The `test` job doesn't set up the DB (no `mix ecto.create`, `mix ecto.migrate`). However, `mix.exs` aliases `test` to include `ecto.create --quiet` and `ecto.migrate --quiet` before running tests, so this is handled transparently.

## Files Involved

- `.github/workflows/ci.yml` — primary file to modify
- `mix.exs` — deps already include dialyxir, no changes needed
- `.credo.exs` — exists, no changes needed
