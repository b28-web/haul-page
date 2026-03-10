# T-029-01 Plan — Document Test Tiers

## Step 1: Create docs/knowledge/test-architecture.md

Write the full test architecture guide with all sections from structure.md.

**Verify:** File exists, all 10 sections present, concrete examples reference real files.

## Step 2: Update CLAUDE.md Test Targeting section

Add test tier table and default-to-lowest-tier rule before the existing "### Rules" subsection.

**Verify:** Read CLAUDE.md, confirm tier table appears above rules, link to test-architecture.md works.

## Step 3: Update .just/system.just _llm recipe

Add one-line test tier summary to Conventions section in the CONTEXT heredoc.

**Verify:** Run `just llm` and confirm test tier line appears in output.

## Step 4: Update docs/knowledge/rdspi-workflow.md

Add tier verification to Review phase description.

**Verify:** Read the file, confirm the new sentence appears in the Review section.

## Step 5: Full test suite

Run `mix test` to confirm no regressions (documentation-only change should be clean).

## Testing Strategy

This is a documentation ticket — no code changes, no new tests needed. Verification is:
1. All four files modified/created correctly
2. `mix test` still passes (no accidental syntax breakage in .ex files)
3. `just llm` output includes test tier info
