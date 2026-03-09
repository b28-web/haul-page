# T-020-03 Design: Preview and Edit

## Problem
After provisioning, the operator has no way to preview their site or request changes. The flow dead-ends at a link.

## Design Decision: Post-Provisioning Edit Mode in ChatLive

### Approach: Extend ChatLive with edit mode

After provisioning completes, ChatLive transitions into "edit mode":
- Preview panel replaces the profile sidebar (shows iframe of live site)
- Chat continues to accept messages, but now interprets them as edit requests
- An `EditHandler` module classifies each edit and applies it
- "Looks good — go live!" button finalizes the session

**Why this approach:**
- Reuses existing chat infrastructure (streaming, messages, PubSub)
- No new LiveView needed — just new state and event handlers
- Operator stays in the same familiar UI
- Preview is a simple iframe to the already-provisioned site

### Rejected alternatives

1. **Separate EditLive page** — Would break the conversational flow. User expects to stay in chat. Would need to duplicate message display, streaming, etc.

2. **Inline HTML preview** — Rendering the full landing page inside the chat panel would be complex (CSS isolation, layout conflicts). An iframe provides natural isolation.

3. **Draft/publish model** — Adding a `published` field to Company and gating the landing page would touch too many existing modules (PageController, TenantResolver). The site is already live after provisioning; previewing the live URL is simpler.

## Edit Classification

Edits fall into two categories:

### Direct updates (no LLM)
Pattern-match on keywords/intent. Examples:
- "Change phone to 555-9999" → update SiteConfig.phone
- "Email should be foo@bar.com" → update SiteConfig.email
- "Business name is actually Haulers Inc" → update SiteConfig.business_name
- "Service area is Greater Portland" → update SiteConfig.service_area

Implementation: regex/pattern matching on the message text. Extract the field and value directly. No LLM call needed.

### LLM-assisted updates
- "Change the tagline to something about same-day service" → call `ContentGenerator.generate_taglines/1` with updated profile, or use a targeted BAML call
- "Make the junk removal description more professional" → regenerate that specific service description
- "Remove Assembly service" → delete Service resource, no LLM needed

Implementation: Use `Chat.send_message/2` (non-streaming) with a structured prompt that returns a JSON edit instruction. Parse and apply.

### Simpler approach chosen: Use LLM for classification + direct execution

Rather than complex regex, send the edit request to the LLM with a system prompt that classifies the intent and returns structured JSON. The LLM response includes:
- `type`: "direct_update" | "regenerate" | "remove_service" | "add_service" | "no_change"
- `field`: the field to update
- `value`: the new value (for direct updates)

But this adds latency and cost for simple changes. **Better: Use a simple Elixir classifier first, fall back to LLM only for content generation.**

### Final design: Hybrid classifier

```
User says "Change phone to 555-9999"
  → EditClassifier.classify(message, profile, tenant)
  → {:direct, :phone, "555-9999"}
  → Update SiteConfig directly
  → Broadcast success

User says "Make the tagline more punchy"
  → EditClassifier.classify(...)
  → {:regenerate, :tagline, "more punchy"}
  → Call ContentGenerator.generate_taglines(updated_profile)
  → Update SiteConfig.tagline
  → Broadcast success

User says "Remove Yard Waste"
  → EditClassifier.classify(...)
  → {:remove_service, "Yard Waste"}
  → Destroy Service resource
  → Broadcast success
```

## Preview Mechanism

- After provisioning, the right sidebar switches from profile panel to preview panel
- Preview panel contains an iframe pointing to the provisioned site URL
- After each edit, push a JS event to reload the iframe (`push_event("reload_preview", %{})`)
- A ChatScroll-style hook handles iframe reload

## State Changes in ChatLive

New assigns after provisioning:
- `edit_mode?` — true after provisioning, enables edit handling
- `edit_count` — number of edits applied (max 10)
- `tenant` — the provisioned tenant (needed for content updates)
- `company` — the provisioned company (for reference)
- `finalized?` — true after "Go live!" clicked

## "Go live!" Button
- Appears in the preview panel after provisioning
- Clicking it:
  - Sets conversation status to `:completed` (already done by provisioner)
  - Sets `finalized?` = true
  - Disables further chat input
  - Shows congratulations message with admin login link

## Edit Round Limit
- `@max_edit_rounds 10`
- After 10 edits, show message: "You've reached the edit limit. You can make further changes in the admin panel."
- Link to `/app/content/site` for manual admin editing

## Test Strategy
- Unit tests for EditClassifier (pattern matching, classification)
- LiveView integration tests for:
  - Preview iframe appears after provisioning
  - Direct edit updates content
  - Edit count limit enforced
  - "Go live!" finalizes session
- No real LLM calls — all via sandbox
