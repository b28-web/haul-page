# T-020-03 Review: Preview and Edit

## Summary

Implemented post-provisioning preview and edit functionality in the chat onboarding flow. After a site is provisioned, the operator can preview it via iframe and request changes through chat. Changes are classified by pattern matching and applied directly to content resources.

## Files Created

| File | Purpose |
|------|---------|
| `lib/haul/ai/edit_classifier.ex` | Classifies chat messages into edit instructions (direct, regenerate, service mgmt) |
| `lib/haul/ai/edit_applier.ex` | Applies classified edits to tenant content resources |
| `assets/js/hooks/preview_reload.js` | JS hook to reload iframe preview after edits |
| `test/haul/ai/edit_classifier_test.exs` | 21 unit tests for classifier patterns |
| `test/haul/ai/edit_applier_test.exs` | 11 integration tests for edit application |
| `test/haul_web/live/preview_edit_test.exs` | 13 LiveView integration tests for edit flow |

## Files Modified

| File | Change |
|------|--------|
| `lib/haul_web/live/chat_live.ex` | Added edit mode state, preview panel component, edit message handling, go-live finalization |
| `assets/js/app.js` | Registered PreviewReload hook |
| `lib/haul/workers/provision_site.ex` | Added `tenant` and `company` to provisioning broadcast |

## Test Coverage

- **45 new tests** (21 classifier + 11 applier + 13 LiveView integration)
- **22 existing ChatLive tests** — all still pass
- **Full suite**: 728 tests, 0 failures (1 excluded baml_live)

### What's tested:
- Edit classification for all supported patterns (phone, email, names, service area, services, tagline, descriptions, unknown)
- Direct SiteConfig updates (phone, email, business_name, owner_name, service_area)
- Service add and remove (soft delete)
- Tagline and description regeneration via ContentGenerator
- Preview panel appears after provisioning with iframe
- Edit count tracking and limit enforcement (max 10)
- "Go live!" finalization disables further input
- Unknown messages return helpful suggestions

### What's NOT tested:
- Actual iframe loading (browser-level, covered by T-020-05 browser QA)
- Preview reload JS hook (requires browser context)
- Concurrent edit sessions (not in scope)

## Acceptance Criteria Verification

| Criterion | Status |
|-----------|--------|
| After provisioning, chat shows preview with link | Done — iframe in sidebar + "Open in new tab" link |
| Operator can request changes in chat | Done — EditClassifier + EditApplier pipeline |
| "Change the tagline" → regenerate tagline | Done — ContentGenerator.generate_taglines called |
| "Remove the Assembly service" → remove | Done — soft delete (active: false) |
| "Phone should be 555-9999" → update directly | Done — direct SiteConfig update |
| Changes that don't need LLM update immediately | Done — :direct edits applied synchronously |
| Changes that need LLM trigger targeted BAML calls | Done — :regenerate edits call ContentGenerator |
| Preview updates after each change | Done — push_event("reload_preview") triggers iframe reload |
| "Looks good — go live!" button finalizes site | Done — sets finalized?, disables input, shows admin link |
| Max 10 edit rounds per session | Done — edit_count tracked, limit message shown |

## Open Concerns

1. **Backwards-compatible provisioning handler**: `handle_info(:provisioning_complete)` now uses `Map.get` for `tenant`/`company` keys and only enters edit_mode? when tenant is present. This prevents crashes when existing tests (T-019-06 chat_qa) broadcast the old payload format without tenant/company.

2. **Service soft delete vs hard delete**: Used `active: false` due to PaperTrail FK constraints on `services_versions`. This matches the same issue in gallery items (see migration `20260309030223_fix_gallery_versions_cascade.exs`). A similar migration for services_versions FK would enable true deletion if needed.

3. **Edit classifier limitations**: The regex-based classifier handles common patterns but won't understand nuanced requests like "Can you make the description sound more friendly?" — these fall through to `:unknown` with a help message. This is acceptable for V1; a future enhancement could route unknown edits to the LLM for classification.

4. **Preview iframe cross-origin**: The iframe loads the operator's subdomain (e.g., `preview-test-co.haulpage.com`). In production, same-site cookies and CORS should work since both the chat and site share the same base domain. In dev, this may require configuring `base_domain` to match.

## Architecture Notes

The edit pipeline follows the existing codebase patterns:
- **EditClassifier** is pure (no side effects, no LLM) — fast and testable
- **EditApplier** wraps Ash resource operations — same pattern as Provisioner
- **ChatLive** delegates to these modules — no business logic in the LiveView
- **Sandbox adapters** enable testing without LLM calls
- **PubSub + push_event** pattern for async UI updates (consistent with provisioning flow)
