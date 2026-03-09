# T-020-02 Design: Auto-Provision Pipeline

## Decision: Architecture

### Option A: Provisioner + Oban Worker + PubSub (chosen)
- `Haul.AI.Provisioner` — pure orchestration module, testable without Oban
- `Haul.Workers.ProvisionSite` — thin Oban wrapper, enqueues and delegates
- PubSub broadcast from worker to ChatLive for real-time UI updates
- ChatLive subscribes to topic `"provisioning:#{session_id}"`

**Why:** Separates orchestration logic from job infrastructure. Provisioner is unit-testable with sandbox adapter. Worker handles retries. PubSub decouples frontend from backend.

### Option B: All logic in Oban Worker
Rejected — mixes orchestration with job concerns, harder to test.

### Option C: GenServer for provisioning
Rejected — Oban already provides process management, retries, persistence. GenServer adds complexity without benefit.

## Decision: Content Generation + Onboarding Integration

### Approach: Onboard first, then overlay generated content
1. Call `Onboarding.run/1` with basic profile data → creates company, tenant, default content
2. Call `ContentGenerator.generate_all/1` → get generated copy
3. Use ProfileMapper to convert profile → resource attrs
4. Update SiteConfig with generated tagline + meta_description
5. Update/create Services with generated descriptions + categories
6. Update SiteConfig with differentiators content

**Why:** Onboarding.run is already idempotent and handles all the heavy lifting (schema, migrations, user). Overlaying generated content after is simple — just Ash updates. No need to modify Onboarding module at all.

**Alternative rejected:** Passing generated content into Onboarding.run. Would require changing its interface and making T-014-01 aware of AI content. Coupling we don't need.

## Decision: Conversation Status

Add `:provisioning` to Conversation status enum. Flow:
- `:active` → `:provisioning` (when pipeline starts)
- `:provisioning` → `:completed` (on success)
- `:provisioning` → `:failed` (on failure after retries exhausted)

Need a new action `:mark_provisioning` on Conversation.
Need a new action `:mark_failed` on Conversation.

## Decision: Pipeline Steps (in order)

```
1. Validate profile (business_name, phone, email required)
2. Mark conversation as :provisioning
3. Generate content (ContentGenerator.generate_all/1)
4. Onboard (Onboarding.run/1 with profile data)
5. Apply generated content to tenant resources
6. Link conversation to company
7. Broadcast success via PubSub
```

On failure at any step:
- Log error with step name + reason
- Mark conversation as :failed (if past step 2)
- Broadcast failure via PubSub

## Decision: Oban Queue

Use `:default` queue (concurrency 5). Provisioning is infrequent and doesn't need its own queue. `max_attempts: 3` with standard backoff.

## Decision: ChatLive UI Changes

### On Profile Complete
- Show "Ready to build your site?" button (instead of link to /app/onboarding)
- Button dispatches `"provision_site"` event
- Disable button after click, show spinner + "Building your site..."

### On Provisioning Success (PubSub broadcast)
- Show success message in chat: "Your site is live!"
- Display site URL as clickable link
- Show admin login link

### On Provisioning Failure (PubSub broadcast)
- Show error message: "Something went wrong — we'll get it sorted out."
- Log details server-side

## Decision: Token/Cost Tracking

Defer persistent storage. For now:
- `Provisioner.from_profile/1` returns timing info in result map
- Logger.info with generation + provisioning durations
- ContentGenerator already logs per-function timing

## Decision: Idempotency

Each step must be safe to retry:
- Profile validation — pure function, always safe
- Conversation status update — idempotent (set to :provisioning)
- Content generation — generates new content (acceptable, costs tokens but no side effects)
- Onboarding.run — already idempotent by design
- Content overlay — Ash updates are idempotent
- Link conversation — idempotent (sets company_id)
- PubSub broadcast — duplicate messages are harmless (UI handles gracefully)

## Decision: Testing Strategy

- Unit test `Provisioner.from_profile/1` with sandbox AI adapter
- Unit test Oban worker enqueue + perform
- Integration test: full pipeline from profile → site live
- ChatLive test: provisioning trigger + PubSub message handling
- All tests use sandbox adapter — no real LLM calls
