# T-006-01 Plan: Content Resources

## Step 1: Create Domain Module + Enum Type

Create `lib/haul/content.ex` (Ash Domain) and `lib/haul/content/endorsement/source.ex` (enum).

**Verify:** Files exist, no compile errors from domain module itself.

## Step 2: Create All Five Resources

Create in order:
1. `lib/haul/content/site_config.ex`
2. `lib/haul/content/service.ex`
3. `lib/haul/content/gallery_item.ex`
4. `lib/haul/content/endorsement.ex`
5. `lib/haul/content/page.ex`

Each follows the pattern from existing resources (Company, Job) and the content-system.md spec.

**Verify:** All files created with correct attributes, actions, multitenancy config.

## Step 3: Register Domain in Config

Add `Haul.Content` to `ash_domains` in `config/config.exs`.

**Verify:** Config updated.

## Step 4: Compile

Run `mix compile --warnings-as-errors` to verify all resources compile.

**Verify:** Zero warnings, zero errors.

## Step 5: Generate Migrations

Run `mix ash_postgres.generate_migrations --name create_content`.

**Verify:** Tenant migration(s) generated in `priv/repo/tenant_migrations/`. Resource snapshots created in `priv/resource_snapshots/repo/tenants/`.

## Step 6: Run Migrations

Run `mix ash_postgres.create && mix ash_postgres.migrate` (if needed) to apply migrations.

Note: Tenant migrations apply when a tenant is provisioned. For testing, we need a tenant schema. May need to run `mix ecto.migrate` for base migrations first, then the test setup will handle tenant creation.

**Verify:** Migrations run successfully, no errors.

## Step 7: Write Tests

Create test files in `test/haul/content/`:
- `site_config_test.exs` — CRUD operations, singleton pattern
- `service_test.exs` — CRUD, sort/filter preparations
- `gallery_item_test.exs` — CRUD, attribute validation
- `endorsement_test.exs` — CRUD, star_rating constraints, source enum, job relationship
- `page_test.exs` — Draft/edit/publish/unpublish lifecycle, slug uniqueness, body_html population

Tests need a tenant. Follow existing test patterns — create a Company first to provision a tenant schema, then create content resources within that tenant.

**Verify:** Test files created.

## Step 8: Run Tests

Run `mix test` to verify all tests pass (both new and existing).

**Verify:** All tests green.

## Testing Strategy

- **Unit tests per resource:** Create, read, update, destroy via Ash API
- **Constraint tests:** star_rating bounds, slug uniqueness, required fields
- **Preparation tests:** Service sort order, active filter
- **Relationship test:** Endorsement with/without Job
- **No integration/browser tests** — resource-level only for this ticket
- **Tenant isolation:** All tests run within a provisioned tenant schema
