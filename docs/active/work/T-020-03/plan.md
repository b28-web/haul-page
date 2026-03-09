# T-020-03 Plan: Preview and Edit

## Step 1: EditClassifier module
Create `lib/haul/ai/edit_classifier.ex` with `classify/1`.
Pattern-match user messages to edit instructions using regex.
Categories: direct updates (phone, email, business_name, owner_name, service_area), service management (remove, add), regeneration (tagline, descriptions), unknown.

Test: `test/haul/ai/edit_classifier_test.exs` — verify each pattern.

Commit: "T-020-03: add EditClassifier for chat edit requests"

## Step 2: EditApplier module
Create `lib/haul/ai/edit_applier.ex` with `apply_edit/3`.
Handles each instruction type:
- `:direct` → update SiteConfig field
- `:regenerate` → call ContentGenerator, update resources
- `:remove_service` → find and destroy Service
- `:add_service` → create Service with defaults
- `:unknown` → return helpful error

Test: `test/haul/ai/edit_applier_test.exs` — verify each edit type against real DB (DataCase).

Commit: "T-020-03: add EditApplier for applying classified edits"

## Step 3: PreviewReload JS hook
Create `assets/js/hooks/preview_reload.js`.
Register in `assets/js/app.js` alongside ChatScroll.

Commit: "T-020-03: add PreviewReload JS hook for iframe refresh"

## Step 4: Modify ProvisionSite worker broadcast
Add `tenant` and `company` fields to the `:provisioning_complete` broadcast payload.
ChatLive needs these to enter edit mode.

Commit: "T-020-03: include tenant in provisioning broadcast"

## Step 5: Extend ChatLive with edit mode
1. New assigns: `edit_mode?` (false), `edit_count` (0), `tenant` (nil), `company` (nil), `finalized?` (false)
2. On `:provisioning_complete`: set edit_mode?, store tenant/company, show preview
3. Modify `send_user_message/2`: when edit_mode?, call `handle_edit/2` instead of LLM
4. `handle_edit/2`: classify → apply → update messages with result → increment edit_count → push reload_preview
5. Add `handle_event("go_live")`: set finalized?, add congratulations message, disable input
6. Add preview_panel component: iframe + "Go live!" button + edit count
7. Conditional render: profile_panel when not edit_mode?, preview_panel when edit_mode?

Test: `test/haul_web/live/preview_edit_test.exs`
- Preview appears after provisioning
- Direct edit (phone change) updates content
- Edit count limit enforced (max 10)
- "Go live!" disables further input
- Unknown edit returns helpful message

Commit: "T-020-03: ChatLive edit mode with preview and go-live"

## Step 6: Final integration test + cleanup
Run full test suite. Fix any issues.
Verify: `mix test` passes.

Commit (if needed): "T-020-03: fix test issues"

## Verification Criteria
- After provisioning, chat shows preview iframe with site URL
- "Change phone to 555-9999" → SiteConfig updated, preview refreshed
- "Remove Junk Removal" → Service destroyed
- "Change tagline" → ContentGenerator called, tagline updated
- 11th edit → message about admin panel
- "Go live!" → session finalized, input disabled
- All tests pass
