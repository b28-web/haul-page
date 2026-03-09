# T-001-03 Plan: CI Pipeline

## Step 1: Add compile and dialyzer steps to quality job

**Action:** Edit `.github/workflows/ci.yml` quality job:
- Insert `- run: mix compile --warnings-as-errors` after `mix deps.get`
- Insert `- run: mix dialyzer` after `mix credo --strict`

**Verification:** Read the file and confirm the quality job now has all 4 required steps (format, credo, dialyzer) plus compile.

## Step 2: Validate CI config locally

**Action:** Run `yamllint` or manual review of YAML syntax. Verify:
- Indentation is consistent (2 spaces)
- All steps are properly formatted
- No YAML syntax errors

**Verification:** The YAML parses without errors.

## Step 3: Verify acceptance criteria

Cross-check every AC line:
- [ ] `.github/workflows/ci.yml` exists
- [ ] test job: Postgres 16, deps.get, compile --warnings-as-errors, test
- [ ] quality job: format --check-formatted, credo --strict, dialyzer
- [ ] Both jobs use erlef/setup-beam with pinned versions matching mise.toml
- [ ] Deps and _build cached by mix.lock hash
- [ ] Pipeline structure is correct for a clean push

## Testing Strategy

- **No unit tests** — this is a CI config file, not application code.
- **Validation:** YAML syntax check, manual AC review.
- **Integration test:** The pipeline itself is the test — it will validate on next push/PR.
- **Local verification:** Run `mix dialyzer` locally to confirm it works with current deps (if possible).

## Commit Plan

Single commit: "Add compile and dialyzer steps to CI quality job"
