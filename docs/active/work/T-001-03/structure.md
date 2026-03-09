# T-001-03 Structure: CI Pipeline

## Files Modified

### `.github/workflows/ci.yml`

**quality job changes (lines ~52-74):**

Current steps:
```
- checkout
- setup-beam
- cache
- mix deps.get
- mix format --check-formatted
- mix credo --strict
```

Target steps:
```
- checkout
- setup-beam
- cache
- mix deps.get
- mix compile --warnings-as-errors
- mix format --check-formatted
- mix credo --strict
- mix dialyzer
```

Changes:
1. Add `mix compile --warnings-as-errors` step after `mix deps.get` and before `mix format`. This ensures BEAM files exist for credo analysis and dialyzer. Using `--warnings-as-errors` for consistency with test job.
2. Add `mix dialyzer` step after `mix credo --strict`.

## Files Not Modified

- `mix.exs` — `dialyxir` already in deps
- `.credo.exs` — already configured
- `config/test.exs` — no changes needed
- `mise.toml` — versions already synced
- No new files created

## Interface Boundaries

N/A — this is a CI config change only. No module boundaries or public interfaces affected.

## Change Ordering

Single atomic change to `.github/workflows/ci.yml`:
1. Add compile step to quality job
2. Add dialyzer step to quality job

Both in one commit since they're in the same file and logically coupled.
