# T-034-01 Research: stale-test-default

## Summary

This ticket changes agent workflow documentation so `mix test --stale` becomes the default during implementation, replacing manual file-path targeting. No source code changes needed.

## Current State

### CLAUDE.md Test Targeting (lines 93–165)

- Line 95: "Run **targeted tests** during implementation, **full suite** before review."
- Lines 99–114: Quick reference code block — shows `mix test` with file paths, directories, line numbers, and full suite. No mention of `--stale`.
- Line 161: Rule 1 says "During implement: run targeted tests after each meaningful change" — generic, no `--stale`.
- Line 162: Rule 2 says "Before review: run `mix test` (full suite)" — correct, no change needed.

### RDSPI Workflow (docs/knowledge/rdspi-workflow.md)

- Line 41 (Implement phase): "Run targeted tests after each change (see CLAUDE.md § Test Targeting for the source→test mapping)."
- Line 49 (Review phase): "Run the full test suite (`mix test`) and note the result." — correct as-is.

### Justfile Structure

- `justfile` (root): Public recipes. No `test-stale` recipe. Has `test-pyramid` at line 49.
- `.just/system.just`: Private recipes. `_test` at line 362 wraps `mix test {{ args }}`. `_test-pyramid` at line 384. No `_test-stale`.

### How `--stale` Works

- ExUnit feature since Elixir 1.3. Uses compile-time module tracing (`.elixir_ls/` manifest) to track which test files depend on which source files.
- Only runs tests whose source dependencies changed since the last successful `mix test` run.
- Typical run: 5–15s vs 97s full suite.
- Caveats: doesn't detect config file or mix.exs changes. Agents must run full suite if they modify configuration.
- Combinable with other flags: `mix test --stale --max-failures 3`.

### `just llm` Briefing

- `.just/system.just` line ~270 mentions: "Test targeting: CLAUDE.md § 'Test Targeting' maps source→test files. Run targeted tests during implement, full suite before review."
- This should also mention `--stale` as the default.

## Files to Modify

| File | What changes |
|------|-------------|
| `CLAUDE.md` | Test Targeting section — add `--stale` as default, document caveats |
| `docs/knowledge/rdspi-workflow.md` | Implement phase — reference `mix test --stale` |
| `.just/system.just` | Add `_test-stale` recipe; update `_llm` test targeting line |
| `justfile` | Add public `test-stale` recipe |

## Constraints

- No source code changes — purely documentation and workflow.
- Must preserve the source→test mapping table (still useful for manual targeting).
- Must document the config-change caveat clearly.
