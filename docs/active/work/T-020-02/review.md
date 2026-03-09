# T-020-02 Review: Auto-Provision Pipeline

## Summary

Implemented the full auto-provision pipeline that takes an operator from chat conversation to a live website. The pipeline is triggered from ChatLive when the operator's profile is complete, runs as an Oban job for resilience, and broadcasts results back to the UI via PubSub.

## Files Changed

### Created
| File | Purpose |
|------|---------|
| `lib/haul/ai/provisioner.ex` (~140 lines) | Orchestration module: validate → generate → onboard → apply content → link conversation |
| `lib/haul/workers/provision_site.ex` (~100 lines) | Oban worker: enqueue, perform, serialize/deserialize profile, PubSub broadcast |
| `test/haul/ai/provisioner_test.exs` (~140 lines) | 7 unit tests for the Provisioner |
| `test/haul/workers/provision_site_test.exs` (~110 lines) | 3 unit tests for the worker |

### Modified
| File | Change |
|------|--------|
| `lib/haul/ai/conversation.ex` | Added `:provisioning` and `:failed` to status enum; added `mark_provisioning` and `mark_failed` actions |
| `lib/haul_web/live/chat_live.ex` | Added provisioning flow: PubSub subscription, `provision_site` event, provisioning/complete/failed handlers, updated profile panel CTA |
| `test/haul_web/live/chat_live_test.exs` | Updated CTA text assertion ("Create my site" → "Build my site") |

## Test Coverage

**10 new tests, 634 total, 0 failures.**

### Provisioner tests (7)
- Full pipeline success (company, site_url, tenant, generated content, timing)
- Conversation linked to company on success
- SiteConfig updated with generated tagline + meta_description
- Services have generated descriptions
- Validation rejects incomplete profiles
- Conversation marked as failed on error
- Idempotent — running twice uses same company

### Worker tests (3)
- Enqueue creates Oban job with correct args
- Perform provisions site and broadcasts success via PubSub
- Perform broadcasts failure on invalid profile

### Coverage gaps
- No dedicated ChatLive test for the provisioning event flow (would require Oban testing setup)
- No test for concurrent provisioning attempts (guarded by `provisioning?` assign)
- No test for PubSub message receipt in LiveView (integration-level)

## Architecture Decisions

1. **Provisioner separated from Worker** — Provisioner is pure orchestration logic, testable without Oban. Worker is a thin wrapper that handles serialization and PubSub.

2. **Onboard first, overlay generated content** — Uses existing `Onboarding.run/1` unchanged, then updates SiteConfig and Services with generated content. No coupling between onboarding and AI modules.

3. **PubSub for UI updates** — Worker broadcasts to `"provisioning:#{session_id}"` topic. ChatLive subscribes on mount. Decoupled from job lifecycle.

4. **Profile serialization** — OperatorProfile struct serialized to string-keyed maps for Oban JSON args, deserialized back in worker. Category atoms handled via `String.to_existing_atom/1` with `:other` fallback.

## Acceptance Criteria Status

| Criterion | Status |
|-----------|--------|
| `Provisioner.from_profile/1` orchestrates full pipeline | Done (as `from_profile/2` with conversation_id) |
| Validate extracted OperatorProfile | Done — checks business_name, phone, email |
| Generate content | Done — delegates to ContentGenerator.generate_all/1 |
| Create Company with slug | Done — via Onboarding.run/1 |
| Provision tenant schema + migrations | Done — via Onboarding.run/1 |
| Create owner User | Done — via Onboarding.run/1 |
| Seed content from generated data | Done — default seed then overlay generated content |
| Return {:ok, %{company, site_url, ...}} | Done |
| Pipeline runs as Oban job | Done — ProvisionSite worker, queue :default, max_attempts 3 |
| Each step is idempotent | Done — tested |
| <30 seconds wall time | Expected ~15-20s with sandbox; real LLM calls ~20-25s |
| Success: "Your site is live!" with link | Done — PubSub message updates ChatLive |
| Failure: error message shown | Done — PubSub failure message updates ChatLive |
| Token usage tracked | Partial — duration_ms tracked and logged; no persistent token storage |

## Open Concerns

1. **Token/cost tracking** — Ticket asks for token usage tracking per provisioning run. Currently only duration is tracked. BAML adapter doesn't expose token counts. This should be a follow-up if needed.

2. **Magic link for owner** — Ticket mentions "Create owner User with magic link" but the current implementation creates a user with a temp password (matching existing Onboarding behavior). Magic link auth would require additional infrastructure.

3. **Race condition on slug** — If two operators with the same business name provision simultaneously, `find_or_create_company` could race. The existing Onboarding module has this same limitation. Low risk for the expected traffic pattern.

4. **Generated content quality** — In sandbox/test mode, fixture data is used. Real quality depends on BAML function prompts + Haiku model. No way to verify without real LLM calls.
