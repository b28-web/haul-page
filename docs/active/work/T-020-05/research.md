# T-020-05 Research: Browser QA — AI Provision Pipeline

## Scope

End-to-end browser QA for the full AI onboarding pipeline: chat conversation → profile extraction → content generation → provisioning → preview/edit → go live → tenant site verification.

## Key Modules & Files

### Chat Flow
- `lib/haul_web/live/chat_live.ex` (918 lines) — Main LiveView for `/start`
  - Three modes: chat (profile extraction), edit (post-provisioning), finalized
  - State: messages, profile, streaming?, provisioning?, edit_mode?, finalized?
  - PubSub subscription to `"provisioning:#{session_id}"`

### AI Pipeline
- `lib/haul/ai/extractor.ex` — BAML ExtractOperatorProfile (Sonnet)
- `lib/haul/ai/content_generator.ex` — 4 BAML functions (Haiku): service descriptions, taglines, why-hire-us, meta description
- `lib/haul/ai/provisioner.ex` — Orchestrates: validate → generate content → onboard → apply content → link conversation
- `lib/haul/workers/provision_site.ex` — Oban worker wrapping Provisioner

### Edit System
- `lib/haul/ai/edit_classifier.ex` — Pattern-matched intent classification (no LLM)
- `lib/haul/ai/edit_applier.ex` — Applies edits to tenant resources

### Tenant Site
- `lib/haul_web/controllers/page_controller.ex` — Landing page (reads SiteConfig + Services)
- `lib/haul_web/live/scan_live.ex` — Scan/gallery page
- `lib/haul_web/live/booking_live.ex` — Booking form
- `lib/haul_web/plugs/tenant_resolver.ex` — Subdomain → tenant resolution

### Test Infrastructure
- `lib/haul/ai/chat/sandbox.ex` — ETS-based sandbox for chat streaming (set_response/set_error)
- `test/support/conn_case.ex` — `clear_rate_limits/0` helper
- BAML sandbox returns hardcoded profile (Junk & Handy, Mike Johnson, etc.)

## Existing Tests

### chat_live_test.exs (16 tests)
Unit tests: mount, send_message, rate limiting, streaming, live extraction, fallback links, error handling.

### chat_qa_test.exs (T-019-06, 19 tests)
QA tests: full conversation flow, streaming UX, profile panel, mobile toggle, provisioning flow (simulated via send/2), conversation persistence, error recovery, rate limiting.

### preview_edit_test.exs (T-020-03, 13 tests)
QA tests: edit mode transition, direct edits (phone/email), service management, tagline regeneration, edit limit, go live, unknown edits. Uses `enter_edit_mode/1` helper that provisions a real tenant.

## Key Patterns

1. **Sandbox adapter**: ChatSandbox.set_response/set_error controls AI responses in tests
2. **Extraction timing**: 800ms debounce + task → tests use Process.sleep(1500)
3. **Provisioning in tests**: preview_edit_test.exs calls `Provisioner.from_profile/2` directly, then simulates PubSub message via `send(view.pid, {:provisioning_complete, ...})`
4. **Tenant cleanup**: on_exit drops all `tenant_%` schemas
5. **BAML sandbox**: Returns hardcoded results (no real API calls in test)

## What T-020-05 Must Cover (vs existing tests)

T-019-06 tests chat flow but only simulates provisioning via `send/2`.
T-020-03 tests edit mode but jumps directly to edit state via helper.

**T-020-05's unique value**: Full pipeline integration — chat → extraction → real provisioning → preview → edit → go live → verify tenant site content. The "magic moment" path.

## Constraints

- Tests use `async: false` (shared DB state, tenant schemas)
- Provisioning creates real DB schemas — must clean up
- Content generation goes through BAML sandbox (returns hardcoded results)
- No real Playwright browser needed — LiveViewTest suffices for this project
- Tenant site pages (landing, /scan, /book) are rendered by different controllers/LiveViews — need separate conn requests with tenant context
