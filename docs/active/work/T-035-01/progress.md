# T-035-01 Progress: Schema Template Clone

## Completed

1. **SchemaTemplate module** (`test/support/schema_template.ex`) — PL/pgSQL `clone_tenant_schema` function, template lifecycle (setup!/teardown!), clone!/1 wrapper.

2. **ProvisionTenant skip flag** — Added `Application.get_env(:haul, :skip_tenant_provision)` guard to `change/3`. Allows creating a company without running migrations.

3. **test_helper.exs** — Template setup on suite start, teardown on suite end.

4. **Factories.build_authenticated_context_fast/1** — Uses schema cloning instead of migrations. Same return shape as `build_authenticated_context/1`.

5. **Benchmark verified:**
   - Migration path: avg 80ms (182ms first call, ~30ms subsequent)
   - Clone path: avg 27ms (33ms first call, ~25ms subsequent)
   - 3x speedup, structural equivalence confirmed (116 columns identical)

## Key fixes during implementation

- PL/pgSQL syntax: `FOR...LOOP...END LOOP` not `FOR...DO...END LOOP`
- Dollar-quoting: `$body$...$body$` instead of `$$...$$` (Postgrex/Ecto conflict)
- Sandbox mode: SchemaTemplate.setup! must restore `:manual` mode after `:auto` DDL work
- `BEGIN...EXCEPTION WHEN duplicate_object THEN NULL; END;` for idempotent FK creation
