# T-034-03 Research: agent-test-targeting

## Current state

### justfile recipes (already exist)

1. **`just test-stale`** — Already in `justfile:53-54` and `.just/system.just:366-367`. Delegates to `mix test --stale`. Accepts extra args.
2. **`just test-file FILE`** — Does NOT exist. The ticket requests this.
3. **`just test` (implicit)** — Not in public justfile. `_test` exists in system.just:362-363 but isn't exposed as a top-level recipe.

### `_llm` recipe (`.just/system.just:170-300`)

Line 270 already mentions `--stale`:
```
- Test targeting: `mix test --stale` (default during implement) — only runs tests whose source deps changed.
  Full suite (`mix test`) before review. If you changed config/*.exs or mix.exs, run full suite.
  See CLAUDE.md § "Test Targeting".
```

This already satisfies the AC: "Update the `_llm` recipe to mention `--stale` as the default test command."

### RDSPI workflow (`docs/knowledge/rdspi-workflow.md`)

Line 41 in the Implement phase already says:
```
Run `mix test --stale` after each change — it only re-runs tests whose source dependencies changed (see CLAUDE.md § Test Targeting).
```

The AC asks for three specific statements:
1. ✅ "After each change, run `mix test --stale` (not `mix test`)" — equivalent wording already present
2. ❌ "Run targeted tests for the specific domain you changed (see CLAUDE.md test mapping)" — NOT present
3. ✅ "Only run `mix test` in the review phase" — present in Review section (line 47: "Run the full test suite (`mix test`)")

### CLAUDE.md test targeting section

Lines in CLAUDE.md already contain extensive test targeting docs:
- Source→test mapping table
- Cross-cutting test list
- Test tier table
- Rules section (lines mention `mix test --stale` during implement, `mix test` before review)

### Verification: agent shell compatibility

`just test-stale` already works. The `export PATH` line in `.just/system.just:8` ensures mise shims are available. The existing OVERVIEW.md notes mention this: "mise shims in justfile — agent shells now find elixir/mix via `export PATH` in system.just."

## Gap analysis

| AC item | Status | Work needed |
|---------|--------|-------------|
| `just test-stale` recipe | ✅ Done | None |
| `just test-file FILE` recipe | ❌ Missing | Add to justfile + system.just |
| Update `_llm` to mention `--stale` | ✅ Done | None |
| RDSPI: "After each change, run --stale" | ✅ Done | None |
| RDSPI: "Run targeted tests for domain" | ❌ Missing | Add sentence to implement phase |
| RDSPI: "Only run mix test in review" | ⚠️ Implicit | Make explicit in implement phase |
| Verify from agent shell | ✅ Done | Already verified |

## Files to modify

1. `.just/system.just` — add `_test-file` private recipe
2. `justfile` — add `test-file` public recipe
3. `docs/knowledge/rdspi-workflow.md` — strengthen implement phase wording
