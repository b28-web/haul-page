# T-011-01 Plan: Onboarding Runbook

## Implementation Steps

### Step 1: Write the runbook

Create `docs/knowledge/operator-onboarding.md` with all sections from structure.md.

This is the only implementation step — the ticket deliverable is a single documentation file.

**Verification:** Read through the document and confirm:
- All 8 steps from the acceptance criteria are covered
- Every step has copy-paste commands
- All env vars are listed with descriptions and examples
- Rollback/teardown steps are included
- Time estimate is stated

### Step 2: Validate commands

Review every shell command in the runbook against actual codebase:
- `fly apps create` syntax matches current flyctl
- Secret names match `config/runtime.exs` env var names exactly
- Release eval commands reference actual module/function paths
- Paths like `/app/bin/haul` match the Dockerfile release structure

### Testing Strategy

No automated tests — this is documentation. Verification is:
1. Commands reference correct env var names (cross-check with `config/runtime.exs`)
2. Module paths in eval commands exist in the codebase
3. Steps are in correct dependency order (can't seed before deploying)
4. Rollback commands use correct flyctl syntax

### Commit Plan

Single commit: `T-011-01: add operator onboarding runbook`
