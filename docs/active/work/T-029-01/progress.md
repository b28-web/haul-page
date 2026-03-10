# T-029-01 Progress — Document Test Tiers

## Completed

1. Created `docs/knowledge/test-architecture.md` — full 3-tier guide with decision tree, examples, factory usage, async guidance, anti-patterns
2. Updated `CLAUDE.md` § Test Targeting — added tier table, default-to-lowest rule (rule 4)
3. Updated `.just/system.just` `_llm` recipe — added test tier summary line in Conventions
4. Updated `docs/knowledge/rdspi-workflow.md` — added tier verification to Review phase

## Verification

- `mix test`: 961 tests, 0 failures (1 excluded)
- `just llm`: test tier line appears in output
- All four acceptance criteria met

## Deviations

None. Plan followed as written.
