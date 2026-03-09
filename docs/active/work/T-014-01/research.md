# T-014-01 Research: mix haul.onboard

## Existing Infrastructure

### Mix Tasks (lib/mix/tasks/haul/)
- `seed_content.ex` — Seeds content from YAML/MD files. Uses `@requirements ["app.start"]`, OptionParser, idempotent upserts via natural keys. Pattern to follow.
- `test_email.ex` — Simple task, shows `Mix.Task.run("app.start")` pattern.

### Company Resource (lib/haul/accounts/company.ex)
- Table: `companies` (public schema, not tenant-scoped)
- Key attrs: `slug` (unique), `name`, `timezone`, `subscription_plan`, `domain`
- `:create_company` action: accepts name/slug, auto-derives slug from name if nil, triggers `ProvisionTenant` change
- `:update_company` action: accepts name/timezone/subscription_plan/stripe_customer_id/domain
- Identities: `unique_slug`, `unique_domain`
- Slug derivation: `name |> downcase |> replace(~r/[^a-z0-9]+/, "-") |> trim("-")`

### Tenant Provisioning (lib/haul/accounts/changes/provision_tenant.ex)
- Ash.Resource.Change running after_action on Company create
- Creates schema: `CREATE SCHEMA IF NOT EXISTS "tenant_#{slug}"`
- Runs tenant migrations: `AshPostgres.MultiTenancy.migrate_tenant(schema, Haul.Repo)`
- Public helper: `tenant_schema(slug)` returns `"tenant_#{slug}"`

### User Resource (lib/haul/accounts/user.ex)
- Tenant-scoped via `:context` multitenancy
- Key attrs: email (ci_string, unique), name, role (:owner/:dispatcher/:crew), phone, hashed_password, active
- AshAuthentication with password + magic_link strategies
- Magic link sender is stubbed (TODO)
- Policies require actor for create (owner role or AshAuthenticationInteraction)
- No explicit `:create` action defined — relies on AshAuthentication-generated actions

### Content Seeding (lib/haul/content/seeder.ex)
- `seed!(tenant, content_root)` — seeds SiteConfig, Service, GalleryItem, Endorsement, Page
- Idempotent via natural key matching (title, before_image_url, customer_name, slug)
- Default content at `priv/content/`, operator overrides at `priv/content/operators/{slug}/`

### Release Module (lib/haul/release.ex)
- `migrate/0` and `rollback/2` only
- `load_app/0` starts :ssl and loads :haul (but doesn't start it)
- This is where `onboard/1` needs to go for production eval support

### Content Resources
- SiteConfig: business_name, phone, email, tagline, service_area, etc. Actions: `:create_default`, `:edit`
- Service: title, description, icon, sort_order. Actions: `:add`, `:edit`
- GalleryItem: before/after URLs, caption. Actions: `:add`, `:edit`
- Endorsement: customer_name, quote_text, star_rating, source. Actions: `:add`, `:edit`
- Page: slug, title, body (rendered to body_html). Actions: `:draft`, `:edit`

## Key Constraints

1. **User creation requires bypassing policies** — The create policy requires either an :owner actor or AshAuthenticationInteraction check. For seeding, we need to use `authorize?: false` or the AshAuthentication interaction context.
2. **Company.create_company already provisions** — Creating a company auto-creates the schema and runs migrations. No separate step needed.
3. **Idempotency for Company** — Need to check if slug exists before creating. Company has no `:upsert` action.
4. **Content seeder is already idempotent** — Just call `Seeder.seed!/2`.
5. **Magic link invite** — The sender is stubbed. Task should create user but note that actual invite email isn't sent yet.
6. **No interactive IO pattern exists** — Need to build prompting from scratch using `Mix.shell().prompt/1`.
7. **Rollback** — Schema creation + data inserts. Could use Repo.transaction for data, but schema creation is DDL (auto-commits in Postgres). True rollback requires DROP SCHEMA.

## File Map

| File | Role |
|------|------|
| lib/mix/tasks/haul/onboard.ex | New — the mix task |
| lib/haul/onboarding.ex | New — core onboarding logic (shared by task + release) |
| lib/haul/release.ex | Modify — add onboard/1 function |
| lib/haul/accounts/company.ex | Read-only — use existing actions |
| lib/haul/accounts/user.ex | Read-only — use existing auth |
| lib/haul/content/seeder.ex | Read-only — call seed!/2 |
| lib/haul/accounts/changes/provision_tenant.ex | Read-only — use tenant_schema/1 |
