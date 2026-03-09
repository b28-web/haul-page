# T-001-03 Review: CI Pipeline

## Summary of Changes

### Files Modified

| File | Change |
|------|--------|
| `.github/workflows/ci.yml` | Added 2 lines to quality job: `mix compile --warnings-as-errors` and `mix dialyzer` |

### What Changed

The quality job was missing two steps required by the acceptance criteria:

1. **`mix compile --warnings-as-errors`** — Added before format/credo/dialyzer. Ensures BEAM files exist for credo's module-level checks and is required for dialyzer. Also catches compilation warnings as errors, consistent with the test job.

2. **`mix dialyzer`** — Added as the final step in the quality job. Uses dialyxir (already in `mix.exs` deps). PLTs are cached via the existing `_build` cache.

## Acceptance Criteria Coverage

| Criterion | Status |
|-----------|--------|
| `.github/workflows/ci.yml` exists | Pass |
| test job: PG 16, deps.get, compile --warnings-as-errors, test | Pass |
| quality job: format --check-formatted, credo --strict, dialyzer | Pass |
| erlef/setup-beam with pinned versions matching mise.toml | Pass — env vars `ELIXIR_VERSION: "1.19"`, `OTP_VERSION: "28"` match `mise.toml` |
| Deps/_build cached by mix.lock hash | Pass — key: `mix-${{ runner.os }}-${{ hashFiles('mix.lock') }}` |
| Pipeline passes on clean push | Not yet verified — requires actual push |

## Test Coverage

This ticket modifies a CI config file only. There are no application code changes to test. The pipeline itself serves as the integration test — it will validate on the next push or PR.

## Open Concerns

1. **Pipeline hasn't been run yet.** The "pipeline passes on clean push" AC can only be verified by actually pushing. The YAML is syntactically correct and the steps match proven patterns.

2. **Dialyzer cold start.** First CI run will build PLTs from scratch (~3-5 min). Subsequent runs will use the cached `_build` directory. If PLT caching proves insufficient, a dedicated PLT cache step can be added later.

3. **Extra jobs beyond AC.** The workflow includes `guardrails` and `deploy` jobs not mentioned in the AC. These were pre-existing and don't conflict with the ticket requirements. Leaving them in place.

4. **MIX_ENV=test for dialyzer.** The workflow sets `MIX_ENV: test` globally. Dialyzer will analyze test-env compilation which includes `test/support` paths. This is fine — it provides broader coverage than dev-only analysis.

## No Known Issues

The change is minimal (2 lines) and follows the existing patterns in the file. No architectural concerns.
