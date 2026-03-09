# T-020-03 Research: Preview and Edit

## Current Architecture

### Chat → Provision Flow (existing)
1. User chats at `/start` via `ChatLive`
2. Profile extracted via `Extractor.extract_profile/1` (800ms debounce)
3. Profile complete → "Build my site" button appears
4. Click → `ProvisionSite` Oban worker enqueued
5. Worker calls `Provisioner.from_profile/2`:
   - Validates profile → generates content (4 BAML calls) → onboards (company + tenant + seeds) → applies generated content → links conversation
6. PubSub broadcasts `{:provisioning_complete, %{site_url, company_name, duration_ms}}`
7. ChatLive shows "Your site is live!" with link

### What Happens After Provisioning
Currently: flow ends. User sees a static link. No preview, no edit capability.

## Key Files and Modules

### ChatLive (`lib/haul_web/live/chat_live.ex`)
- 710 lines, handles full chat + extraction + provisioning flow
- State: `messages`, `profile`, `provisioning?`, `provisioned_url`, `session_id`, `conversation`
- After provisioning: sets `provisioned_url`, shows "View your site" link
- No edit state or preview iframe currently

### Provisioner (`lib/haul/ai/provisioner.ex`)
- `from_profile/2` — full pipeline, returns `{:ok, %{company, site_url, tenant, generated_content, duration_ms}}`
- `apply_generated_content/3` — updates SiteConfig (tagline, meta_desc) + Service descriptions
- Returns generated_content map with keys: `:service_descriptions`, `:taglines`, `:why_hire_us`, `:meta_description`

### ContentGenerator (`lib/haul/ai/content_generator.ex`)
- Individual functions: `generate_service_descriptions/1`, `generate_taglines/1`, `generate_why_hire_us/1`, `generate_meta_description/1`
- `generate_all/1` — runs all 4 sequentially
- Each takes OperatorProfile, returns parsed results

### Content Resources (multi-tenant)
- `SiteConfig` — business_name, phone, email, tagline, service_area, owner_name, meta_description, etc. Action: `:edit`
- `Service` — title, description, icon, category, sort_order, active. Actions: `:add`, `:edit`, `:destroy`
- Both use `:context` multitenancy, require `tenant:` option

### ProfileMapper (`lib/haul/ai/profile_mapper.ex`)
- `to_site_config_attrs/1`, `to_service_attrs_list/1` — pure data transforms from OperatorProfile

### OperatorProfile (`lib/haul/ai/operator_profile.ex`)
- Struct: business_name, owner_name, phone, email, service_area, tagline, years_in_business, services, differentiators
- ServiceOffering: name, description, category

### Landing Page Rendering
- `PageController.home/2` → `operator_home/1` renders the operator's landing page
- Uses `ContentHelpers.resolve_tenant/0` and `load_site_config/1`, `load_services/1`
- Served at `/` on operator subdomain (e.g., `junk-and-handy.haulpage.com`)

### PubSub Pattern
- Topic: `"provisioning:#{session_id}"`
- Messages: `{:provisioning_complete, result}`, `{:provisioning_failed, details}`

### Chat Sandbox
- `Chat.Sandbox.set_response/1` — global ETS override for chat responses
- `Chat.Sandbox.set_error/1` — simulate LLM errors
- AI Sandbox: `Haul.AI.Sandbox.set_response/2` — per-process process dict override

### Conversation Resource
- Status atoms: `:active`, `:completed`, `:abandoned`, `:provisioning`, `:failed`
- Actions: `:add_message`, `:save_profile`, `:link_to_company`, `:mark_provisioning`, `:mark_failed`
- `company_id` set on successful provisioning

## Constraints & Boundaries

### What changes can be made post-provisioning?
1. **Direct updates (no LLM):** phone, email, business_name, owner_name, service_area — just update SiteConfig
2. **LLM-regeneration:** tagline, service descriptions, meta_description — call specific ContentGenerator function
3. **Service management:** add/remove services — update Service resources + optionally regenerate descriptions

### Preview mechanism
- The site is served at `{slug}.{base_domain}` via subdomain routing
- Preview can be an iframe pointing to the live URL, or a link to open in new tab
- Alternatively: render inline in chat using content data (not full page)

### Edit round limit
- Ticket requires max 10 edit rounds per session
- Need a counter in LiveView state

### "Go live" finalization
- Currently provisioning already creates a live site
- "Go live" could mean: conversation status → completed, disable further edits
- Or: site could be created in "draft" mode and published on "Go live" — but Company has no `published` field
- Simplest: the site IS live after provisioning; "Go live" just closes the edit session

## Existing Patterns to Follow

- Chat messages as `%{id, role, content}` maps in LiveView state
- PubSub for async operation results
- Task.start for background LLM calls
- Sandbox adapters for test isolation
- Ash Changeset pattern for resource updates
- `tenant:` option on all content reads/writes
