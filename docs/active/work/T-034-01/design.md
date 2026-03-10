# T-034-01 Design: stale-test-default

## Decision

Make `mix test --stale` the recommended default for the implementation phase. Keep `mix test` (full suite) for review phase. Add `just test-stale` as a convenience alias.

## Approach

### Option A: Replace targeted tests with `--stale` as default (CHOSEN)

Update CLAUDE.md and RDSPI workflow to recommend `--stale` as the primary testing command during implementation. Keep the source→test mapping table as a fallback for when agents need to run specific files.

**Pros:**
- Zero cognitive load — agents don't need to figure out which test files correspond to their changes
- Compile-time tracing is more accurate than manual mapping
- 5–15s typical run vs manually selecting files
- No code changes needed

**Cons:**
- Doesn't detect config/mix.exs changes (documented caveat)
- Agents lose awareness of the source→test mapping (mitigated by keeping the table)

### Option B: Add `--stale` as secondary option alongside file targeting

Mention `--stale` but keep file-path targeting as the primary recommendation.

**Rejected:** The whole point of this ticket is that `--stale` is strictly better than manual targeting for the common case. Making it secondary defeats the purpose.

### Option C: Create a custom mix task wrapping `--stale` with config-change detection

Build `mix haul.test_smart` that checks git diff for config changes and falls back to full suite.

**Rejected:** Over-engineering. The caveat is simple enough to document. Agents can follow a rule.

## Design Decisions

1. **`--stale` is the default, file paths are the fallback.** The quick reference section reorders to put `--stale` first.
2. **Config caveat is a rule.** Add rule: "If you changed config/*.exs or mix.exs, run `mix test` instead of `--stale`."
3. **`just test-stale` is a convenience alias.** Mirrors `just test-pyramid` pattern.
4. **`just llm` briefing updated.** Agents onboarded via `just llm` learn about `--stale` immediately.
5. **Source→test mapping table preserved.** Still useful for targeted debugging and understanding the codebase.
