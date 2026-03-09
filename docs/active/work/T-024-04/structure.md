# T-024-04 Structure: Agent Test Targeting

## Files modified

### 1. `CLAUDE.md` — Add "Test Targeting" section
Location: After the existing "Code Conventions" section, before any other sections.

New section "Test Targeting" with:
- **Mapping table**: Domain → source glob → test paths → cross-cutting tests
- **Command examples**: single file, directory, multi-path, line number
- **Cross-cutting tests**: when to run tenant isolation, smoke, QA tests
- **Full suite rule**: always run `mix test` before final review

Approximately 60-80 lines added.

### 2. `docs/knowledge/rdspi-workflow.md` — Add test guidance to Implement and Review phases
Two small additions:
- Implement phase: Add sentence about running targeted tests
- Review phase: Add sentence about running full suite

Approximately 4 lines changed.

### 3. `.just/system.just` — Update `_llm` recipe
Add a brief mention of test targeting convention in the Conventions section of the `just llm` output.

Approximately 2 lines added.

## Files NOT modified
- No new test files created
- No ExUnit tags added to existing test files
- No new scripts or modules
- No justfile recipes added
- No config changes

## Module boundaries
This ticket is purely documentation. No code modules are created or modified.

## Ordering
1. CLAUDE.md first (primary artifact — agents read this)
2. RDSPI workflow second (supplements CLAUDE.md)
3. `just llm` third (brief reference for agent onboarding)
