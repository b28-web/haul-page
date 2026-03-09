# T-020-03 Structure: Preview and Edit

## New Files

### `lib/haul/ai/edit_classifier.ex`
Module: `Haul.AI.EditClassifier`

Public API:
```elixir
classify(message :: String.t()) :: edit_instruction()

@type edit_instruction ::
  {:direct, field :: atom(), value :: String.t()}
  | {:regenerate, target :: atom(), hint :: String.t()}
  | {:remove_service, service_name :: String.t()}
  | {:add_service, service_name :: String.t()}
  | {:unknown, message :: String.t()}
```

Implementation: Pattern matching with regex. No LLM call.

Patterns:
- Phone: `~r/phone.*?(\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4})/i` → `{:direct, :phone, value}`
- Email: `~r/email.*?([\w.+-]+@[\w.-]+\.\w+)/i` → `{:direct, :email, value}`
- Business name: `~r/(?:business|company)\s+name.*?(?:is|to|should be)\s+["']?(.+?)["']?\s*$/i` → `{:direct, :business_name, value}`
- Service area: `~r/service\s+area.*?(?:is|to|should be)\s+(.+)$/i` → `{:direct, :service_area, value}`
- Owner name: `~r/(?:owner|my)\s+name.*?(?:is|to|should be)\s+(.+)$/i` → `{:direct, :owner_name, value}`
- Remove service: `~r/remove\s+(?:the\s+)?(.+?)\s*(?:service)?$/i` → `{:remove_service, name}`
- Tagline: `~r/(?:tagline|slogan|motto)/i` → `{:regenerate, :tagline, message}`
- Description: `~r/(?:description|describe)/i` → `{:regenerate, :descriptions, message}`
- Fallback: `{:unknown, message}`

### `lib/haul/ai/edit_applier.ex`
Module: `Haul.AI.EditApplier`

Public API:
```elixir
apply_edit(instruction :: edit_instruction(), tenant :: String.t(), profile :: OperatorProfile.t())
  :: {:ok, String.t()} | {:error, String.t()}
```

Returns a human-readable confirmation message on success.

Handles:
- `{:direct, field, value}` → update SiteConfig via `:edit` action
- `{:regenerate, :tagline, hint}` → call `ContentGenerator.generate_taglines/1`, pick first, update SiteConfig
- `{:regenerate, :descriptions, hint}` → call `ContentGenerator.generate_service_descriptions/1`, update Services
- `{:remove_service, name}` → find Service by title, destroy
- `{:add_service, name}` → create Service with default icon
- `{:unknown, _}` → return error message suggesting specific changes

### `assets/js/hooks/preview_reload.js`
Simple JS hook that reloads an iframe when receiving a `reload_preview` event.

```js
export const PreviewReload = {
  mounted() {
    this.handleEvent("reload_preview", () => {
      const iframe = this.el.querySelector("iframe")
      if (iframe) iframe.src = iframe.src
    })
  }
}
```

### `test/haul/ai/edit_classifier_test.exs`
Unit tests for pattern matching classification.

### `test/haul/ai/edit_applier_test.exs`
Integration tests for applying edits to content resources.

### `test/haul_web/live/preview_edit_test.exs`
LiveView integration tests for the preview + edit flow.

## Modified Files

### `lib/haul_web/live/chat_live.ex`
Changes:
1. Add new assigns in mount: `edit_mode?`, `edit_count`, `tenant`, `company`, `finalized?`
2. Modify `handle_info({:provisioning_complete, ...})` to enter edit mode
3. Add `handle_event("apply_edit", ...)` — classify + apply edit via message
4. Add `handle_event("go_live", ...)` — finalize session
5. Modify `send_user_message/2` to route to edit handler when `edit_mode?` is true
6. Add preview panel component (replaces profile panel when in edit mode)
7. Add "Go live!" button in preview panel

### `assets/js/app.js`
Register the `PreviewReload` hook alongside existing `ChatScroll` hook.

### `lib/haul/workers/provision_site.ex`
Modify PubSub broadcast to include `tenant` and `company` in the result payload so ChatLive can enter edit mode with the right context.

## Component Boundaries

```
ChatLive (orchestrator)
  ├── send_user_message() → when edit_mode?, delegates to handle_edit()
  ├── handle_edit() → EditClassifier.classify() → EditApplier.apply_edit()
  ├── profile_panel() — shown pre-provisioning (existing)
  ├── preview_panel() — shown post-provisioning (new)
  └── go_live() — finalizes session

EditClassifier (pure function, no side effects)
  └── classify(message) → instruction tuple

EditApplier (side effects: DB writes, LLM calls)
  └── apply_edit(instruction, tenant, profile) → {:ok, msg} | {:error, msg}
```

## Ordering of Changes
1. Create EditClassifier (pure, testable independently)
2. Create EditApplier (depends on existing Ash resources)
3. Create PreviewReload hook + register in app.js
4. Modify ProvisionSite worker to include tenant in broadcast
5. Modify ChatLive to add edit mode + preview panel
6. Write tests
