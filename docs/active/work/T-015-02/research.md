# T-015-02 Research: Onboarding Wizard

## What exists

### Authentication & routing
- Router: `/app` scope uses `:authenticated` live_session with `AuthHooks.require_auth` on_mount
- AuthHooks: verifies JWT from session, requires `:owner` or `:dispatcher` role, sets `current_user`, `current_company`, `current_path`
- Admin layout: sidebar + header, used by all `/app` routes. Sidebar has Content submenu, Bookings, Settings
- Company loaded from tenant slug in auth hooks: `load_company/1` strips "tenant_" prefix

### Company resource (lib/haul/accounts/company.ex)
- Attributes: slug, name, timezone, subscription_plan, stripe_customer_id, domain
- **No `onboarding_complete` field exists** — needs migration + attribute + action update
- Actions: `:create_company` (accepts name, slug, timezone, subscription_plan, domain), `:update_company` (same minus slug)
- `:update_company` does NOT accept `onboarding_complete` — must add to accept list
- Public schema (not tenant-scoped). Table: `companies`

### Onboarding module (lib/haul/onboarding.ex)
- `signup/1`: creates company → provisions tenant → seeds content → creates owner user
- `derive_slug/1`: "Joe's Hauling" → "joes-hauling"
- `slug_available?/1`: checks Company table for slug uniqueness
- `site_url/1`: returns "https://#{slug}.#{base_domain}"
- After signup, user is redirected to `/app` via AppSessionController (POST /app/session with JWT)

### Signup flow (lib/haul_web/live/app/signup_live.ex)
- Collects: name, email, phone, area, password, password_confirmation
- Derives slug from name, shows availability check
- On success: sets token + tenant assigns, triggers phx-trigger-action → POST to /app/session
- After login, user lands at `/app` (DashboardLive)
- **No redirect to onboarding wizard currently** — need to add redirect logic

### Content resources (all tenant-scoped, multitenancy :context)
- **SiteConfig** (lib/haul/content/site_config.ex): business_name, phone, email, tagline, service_area, address, coupon_text, meta_description, primary_color, logo_url. Actions: `:create_default`, `:edit`
- **Service** (lib/haul/content/service.ex): title, description, icon, sort_order, active. Actions: `:add`, `:edit`, `:destroy`
- **GalleryItem**: before/after images, caption, sort_order, featured, active
- **Endorsement**: customer_name, quote_text, star_rating, source, date, featured, active, sort_order

### Content admin LiveViews (lib/haul_web/live/app/)
- **SiteConfigLive**: AshPhoenix.Form for create/update, fieldsets for Business Info, Location, Appearance, SEO
- **ServicesLive**: CRUD with add/edit/delete/reorder, modal form, icon selector
- **GalleryLive**: file upload pattern with `allow_upload`, `consume_uploaded_entries`, Storage module
- **EndorsementsLive**: CRUD with star rating, source dropdown, featured/active toggles

### File upload pattern (from GalleryLive + Storage)
- `allow_upload(:image_name, accept: ~w(.jpg .jpeg .png .webp), max_entries: 1, max_file_size: N)`
- `consume_uploaded_entries/3` reads binary → `Storage.put_object(key, binary, content_type)`
- `Storage.upload_key(tenant, prefix, filename)` → unique key
- `Storage.public_url(key)` → URL string
- Storage backends: :local (default) or :s3

### Content seeding (lib/haul/content/seeder.ex)
- `Seeder.seed!(tenant, content_root)` — idempotent, seeds from YAML/MD files
- Default content in `priv/content/defaults/`
- Called during signup → services, gallery items, endorsements pre-populated

### Test patterns (test/support/conn_case.ex)
- `create_authenticated_context/1`: creates company, provisions tenant, registers owner user, returns `%{company, tenant, user, token}`
- `log_in_user/2`: sets session with user_token and tenant
- `cleanup_tenants/0`: drops all tenant_* schemas (used in on_exit)
- LiveView tests: `live(conn, path)` → `{:ok, view, html}`, form/render_change/render_submit

## Key constraints
1. Company.onboarding_complete field doesn't exist — needs public migration
2. `:update_company` action must accept the new field
3. Wizard must work within `:authenticated` live_session (AuthHooks already verified)
4. All content ops need `tenant: tenant` passed to Ash
5. Subdomain change = Company slug change = tenant schema rename — **extremely complex**, probably should not allow subdomain changes in wizard (slug is set at signup)
6. Services are pre-populated by seeder during signup — wizard step 3 shows existing, allows editing
7. Logo upload goes into SiteConfig.logo_url via Storage module
8. Preview step: can link to `Onboarding.site_url(company.slug)` — opens in new tab

## Open questions
- Should the wizard use the admin sidebar layout or a standalone layout?
- Subdomain step: changing slug after signup is dangerous (requires schema rename). Safer to show current and allow domain change only.
- How to handle "Go Live" if site is already live (re-visit wizard)?
