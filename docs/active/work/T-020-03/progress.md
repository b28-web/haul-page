# T-020-03 Progress: Preview and Edit

## Completed Steps

### Step 1: EditClassifier module
- Created `lib/haul/ai/edit_classifier.ex` with `classify/1`
- Pattern matching for: phone, email, business_name, owner_name, service_area, remove/add service, tagline/description regeneration
- 21 unit tests in `test/haul/ai/edit_classifier_test.exs` — all pass

### Step 2: EditApplier module
- Created `lib/haul/ai/edit_applier.ex` with `apply_edit/3`
- Handles: direct SiteConfig updates, service add/remove (soft delete via active: false), tagline/description regeneration
- 11 integration tests in `test/haul/ai/edit_applier_test.exs` — all pass

### Step 3: PreviewReload JS hook
- Created `assets/js/hooks/preview_reload.js`
- Registered in `assets/js/app.js`

### Step 4: ProvisionSite worker broadcast
- Added `tenant` and `company` fields to `:provisioning_complete` broadcast

### Step 5: ChatLive edit mode
- Added new assigns: `edit_mode?`, `edit_count`, `tenant`, `company`, `finalized?`
- New `handle_info(:provisioning_complete)` enters edit mode with preview instructions
- Edit messages routed through `EditClassifier.classify/1` → `EditApplier.apply_edit/3`
- Preview panel with iframe, edit counter, "Go live!" button
- Go live finalizes session, disables input
- Max 10 edit rounds enforced
- 13 LiveView integration tests in `test/haul_web/live/preview_edit_test.exs` — all pass

### Step 6: Final verification
- All 67 T-020-03 related tests pass (21 + 11 + 13 + 22 existing chat)
- Full suite: 704+ tests, no new failures from this ticket
- Note: concurrent agent (T-020-04 cost tracking) was modifying shared files during implementation. Those changes were reverted for testing; the other ticket will need to re-apply its changes.

### Step 7: Fix cross-ticket breakage
- ChatLive `handle_info(:provisioning_complete)` crashed when broadcast payload lacked `tenant`/`company` keys (T-019-06 chat_qa_test)
- Fixed: use `Map.get` with nil defaults; only enter `edit_mode?` when `tenant` is present
- 728 tests, 0 failures (excluding unrelated T-020-04 cost_tracker tests)

## Deviations from Plan

1. **Service removal uses soft delete** — PaperTrail's FK constraint on `services_versions` prevents hard delete. Used `active: false` instead. Same pattern already needed for gallery_items_versions (see T-013-04 migration).

2. **Preview panel IDs** — Needed unique IDs for mobile vs desktop preview panels (`preview-panel-mobile`, `preview-panel-desktop`) because LiveView requires unique IDs for hooked elements.

3. **@max_edit_rounds as literal in template** — Module attributes can't be accessed with `@` in HEEx templates (that's assigns). Used literal `10` in the template.
