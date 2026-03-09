# T-020-02 Research: Auto-Provision Pipeline

## Existing Infrastructure

### Content Generation (T-020-01 — done)
- `Haul.AI.ContentGenerator.generate_all/1` accepts an OperatorProfile, returns:
  - `service_descriptions` — map of service name → 2-3 sentence description
  - `taglines` — 3 options (short, benefit, professional)
  - `why_hire_us` — 6 bullet points
  - `meta_description` — SEO description ≤160 chars
- Uses Claude Haiku via BAML for cost efficiency
- Retry logic for transient errors built in
- Sandbox adapter returns fixture data in test/dev

### Onboarding Orchestration (T-014-01 — done)
- `Haul.Onboarding.run(%{name, phone, email, area})` performs:
  1. Validate name + email presence
  2. Derive slug from business name
  3. Find or create Company (by slug)
  4. Provision tenant schema + run migrations
  5. Seed default content from `priv/content/defaults/`
  6. Update SiteConfig with phone/email/service_area
  7. Find or create owner User with :owner role
- Returns `{:ok, %{company, tenant, user, content, existing_company}}`
- Idempotent — safe to re-run on partial failure
- `Haul.Onboarding.site_url/1` constructs live URL

### Live Extraction (T-019-02 — done)
- ChatLive extracts profile async with 800ms debounce
- Tracks `profile_complete?` when business_name + phone + email present
- Profile panel shows "Your profile is complete!" CTA
- Conversation resource stores extracted_profile as JSON map
- Conversation has `:link_to_company` action (sets company_id, status → :completed)

### Profile Mapper (exists)
- `Haul.AI.ProfileMapper.to_company_attrs/1` → %{name: business_name}
- `Haul.AI.ProfileMapper.to_site_config_attrs/1` → site config fields
- `Haul.AI.ProfileMapper.to_service_attrs_list/1` → service list with icons
- `Haul.AI.ProfileMapper.to_differentiators_content/1` → markdown bullets
- `Haul.AI.ProfileMapper.missing_fields/1` → required field check

## Oban Patterns in Codebase

### Configuration (config/config.exs)
- Queues: `notifications: 10, default: 5, certs: 3`
- Cron plugin for scheduled workers
- Workers use `use Oban.Worker, queue: :default, max_attempts: 3`

### Existing Workers
- `Haul.Workers.CleanupConversations` — cron, marks stale conversations abandoned
- `Haul.Workers.ProvisionCert` — queue :certs, dispatched with action + company_id args
- `Haul.Workers.CheckDunningGrace` — cron, billing grace period checks

### Worker Pattern
- Args passed as string-keyed maps
- `perform/1` matches on `%Oban.Job{args: %{...}}`
- Return `:ok` on success, `{:error, reason}` on failure
- Oban handles retry with backoff automatically

## Chat Live Integration Points

### Current Assigns
- `profile` — %OperatorProfile{} or nil
- `profile_complete?` — boolean
- `conversation` — %Conversation{}
- `session_id` — UUID

### Event Flow After Profile Complete
Currently: profile panel shows CTA linking to `/app/onboarding`
Needed: trigger provisioning pipeline, show "site is live" or error

### PubSub
- `Haul.PubSub` available in supervision tree
- Can broadcast provisioning status updates to ChatLive

## Conversation Resource Actions
- `:link_to_company` — sets company_id + status to :completed
- `:mark_abandoned` — sets status to :abandoned
- No current "provisioning" status — may need one

## Gap Analysis

### What's Missing
1. **Provisioner module** — orchestrates generate → onboard → link_to_company
2. **Oban worker** — wraps Provisioner for resilience
3. **ChatLive integration** — trigger worker, listen for results, update UI
4. **Content override in Onboarding** — currently seeds defaults; need to seed generated content
5. **Conversation status for provisioning** — need `:provisioning` status
6. **Token/cost tracking** — ticket asks for it but no infrastructure exists

### Content Seeding Gap
`Haul.Onboarding.run/1` seeds defaults then updates SiteConfig. But we need to:
- Seed generated service descriptions (not defaults)
- Seed generated tagline + meta description into SiteConfig
- Seed differentiators into why-hire-us content
- The Seeder seeds from files; we need to seed from generated data

### Options for Content Override
1. Onboard with defaults, then overwrite with generated content after
2. Skip default seeding, seed generated content directly
3. Pass generated content into Onboarding.run as optional parameter

Option 1 is simplest and stays idempotent — onboard, then update.

### Timing Constraint
Ticket says <30 seconds. Content generation (4 LLM calls) ~10-15s. Onboarding (schema create + migrations + seed) ~5s. Total ~15-20s — feasible.

### Token Tracking
No existing infrastructure. Could add to Provisioner return value but defer tracking storage to a future ticket. Log it for now.
