# T-034-03 Design: agent-test-targeting

## Decision

Most of the ticket's ACs are already satisfied by prior work (T-024-04, T-034-01). The remaining work is:

1. Add `just test-file FILE` recipe
2. Strengthen RDSPI implement phase with domain-targeting guidance

### Approach: `test-file` recipe

**Option A: Thin wrapper** — `mix test {{FILE}}`
Simple, matches the pattern of `test-stale`. Accepts a file path or `path:line` argument.

**Option B: Validation wrapper** — Check file exists before running
Over-engineered. `mix test` already gives a clear error for missing files.

**Decision: Option A.** Consistency with `test-stale` pattern. No value in validation.

### Approach: RDSPI wording

The implement phase already mentions `mix test --stale`. The gap is:
- No mention of domain-targeted testing (run tests for the specific domain you changed)
- No explicit "do NOT run full suite during implement"

**Decision:** Add two sentences to the existing implement paragraph. Keep it concise — agents already have the CLAUDE.md test mapping table, so just reference it.

### What was rejected

- Adding a `just test-domain DOMAIN` recipe that auto-maps domains to test paths. Too complex, not in AC, and the CLAUDE.md mapping table already serves this purpose.
- Adding `--max-failures 5` to `test-stale` recipe. The AC suggests this but the existing recipe already accepts args so agents can pass `--max-failures 5` themselves. Hardcoding it removes flexibility.

## Risk

None. Documentation + justfile recipe. No source code changes.
