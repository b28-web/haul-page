# T-024-04 Design: Agent Test Targeting

## Problem
Agents run the full 746-test suite (~96s) to validate every change. Most changes touch one domain and only need 5-30 tests (~0.06-5s). Agents need guidance on which tests to run.

## Options evaluated

### Option A: ExUnit domain tags
Add `@moduletag :domain_accounts`, `@moduletag :domain_billing`, etc. to every test file. Agents use `mix test --only domain_accounts`.

**Pros:** Semantic targeting, can cross-cut (one test tagged with multiple domains).
**Cons:** 85 files to tag, maintenance burden, no advantage over file paths for this codebase's 1:1 mapping. Tags are redundant when directory structure already encodes domain.

**Rejected:** High effort, low marginal value over file paths.

### Option B: Script that auto-discovers tests from changed files
A `test/test_map.exs` script that takes source file paths and returns test file paths using naming conventions.

**Pros:** Automated, agents could pipe `git diff --name-only` through it.
**Cons:** Over-engineered for the actual need. Agents are LLMs — they can reason about file path mappings from a table. A script adds code to maintain.

**Rejected:** Unnecessary automation. A static mapping table is simpler and equally effective.

### Option C: Static mapping table in CLAUDE.md + RDSPI test guidance (chosen)
Add a "Test Targeting" section to CLAUDE.md with:
1. Domain → test file mapping table
2. Cross-cutting test guidance (when to run isolation tests, smoke tests)
3. Examples of targeted test commands

Update RDSPI workflow to recommend:
- During Implement: run targeted tests after each change
- Before Review: run full suite once

**Pros:** Zero code to maintain. Agents already read CLAUDE.md. Mapping table is easy to update when new domains are added. Fits existing conventions.
**Cons:** Static — must be updated manually when test files change.

**Chosen because:** The problem is information asymmetry, not tooling. Agents know how to run `mix test path`. They don't know which paths are relevant. A mapping table solves this directly.

### Option D: `just test-for` recipe
A justfile recipe like `just test-for billing` that expands to the right test paths.

**Pros:** Single command for agents.
**Cons:** Another layer of indirection. Agents can already run `mix test` directly. The mapping knowledge still needs to live somewhere (the recipe body or a data file).

**Rejected:** Adds complexity without meaningful benefit. Agents can copy-paste paths from CLAUDE.md.

## Decision

**Option C: Static mapping in CLAUDE.md + RDSPI update.**

### Mapping table design
Group by domain (matching `lib/haul/` directories), with columns:
- Domain/area
- Source paths (globs)
- Test paths (specific files/dirs)
- Cross-cutting tests to also run

### RDSPI update
Add two sentences to the Implement and Review phase descriptions:
- Implement: "Run targeted tests after each change (see CLAUDE.md § Test Targeting)"
- Review: "Run full suite (`mix test`) before writing review.md"

### Verification
Run a representative targeted test set and verify it completes in <15 seconds (AC requirement). Already confirmed: multi-domain targeted run = ~5 seconds.
