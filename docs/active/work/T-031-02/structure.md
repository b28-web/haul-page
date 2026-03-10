# T-031-02 Structure: verify-test-switching

## Files Modified

### `docs/knowledge/test-architecture.md`
Add new section "Adapter Switching" after the existing "Anti-Patterns" section. Content:

1. **How it works** — `@adapter Application.compile_env(...)` pattern, module attribute binding
2. **Environment matrix** — table showing adapter per environment (test/dev/prod)
3. **Adding a new adapter** — step-by-step guide (behaviour, implementations, config entries)
4. **Recompilation note** — `mix compile --force` or automatic detection

### `config/test.exs`
Add the 2 missing explicit adapter entries (`:chat_adapter`, `:cert_adapter`) for completeness. They already default to Sandbox via config.exs, but being explicit in test.exs makes the test contract clear and matches the other 5 adapters.

## Files Not Modified

- No source code changes — this is a verification + documentation ticket
- No new test files — existing 975 tests verify adapter dispatch
- No config/prod.exs or config/runtime.exs changes
