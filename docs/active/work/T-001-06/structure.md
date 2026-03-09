# T-001-06 Structure: mix setup

## Files modified

### `priv/repo/seeds.exs`
- Replace placeholder with functional seed script
- Log operator identity from application config
- Include idempotency guards
- Mark sections for future Ash resource seeds (Company, User, etc.)

### `test/haul/config_test.exs` (new)
- Test that `:operator` config is loaded with all expected keys
- Test that services list is non-empty and well-structured
- Verifies that the config foundation seeds rely on is correct

## Files unchanged

### `mix.exs`
- Current `setup` alias already covers all required steps
- No changes needed — the alias chain works correctly

### `config/config.exs`, `config/dev.exs`, `config/test.exs`
- No changes needed — config is already well-structured

## Module boundaries

No new modules. Seeds are a script, not a module. Test file uses standard ExUnit.

## Ordering

1. Write seeds.exs (independent)
2. Write config_test.exs (independent)
3. Verify `mix setup` end-to-end (depends on 1)
