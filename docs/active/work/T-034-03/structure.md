# T-034-03 Structure: agent-test-targeting

## Files modified

### `.just/system.just`

Add after `_test-stale` block (line ~367):

```just
[private]
_test-file FILE *args='':
    mix test {{ FILE }} {{ args }}
```

### `justfile`

Add after `test-stale` entry (line ~54):

```just
# Run tests for a specific file or file:line
test-file FILE *args='':
    @just _test-file {{ FILE }} {{ args }}
```

### `docs/knowledge/rdspi-workflow.md`

Modify the Implement phase paragraph (line 41). Replace the single sentence about `mix test --stale` with a more explicit block:

Current:
```
Run `mix test --stale` after each change — it only re-runs tests whose source dependencies changed (see CLAUDE.md § Test Targeting).
```

New (3 sentences):
```
After each change, run `mix test --stale` (not `mix test`) — it only re-runs tests whose source dependencies changed (~5-15s vs ~97s full suite). For targeted verification, also run tests for the specific domain you changed (see CLAUDE.md § Test Targeting for the source→test mapping). Save `mix test` (full suite) for the Review phase.
```

## Files NOT modified

- `CLAUDE.md` — already has comprehensive test targeting docs
- `_llm` recipe — already mentions `--stale` as default
