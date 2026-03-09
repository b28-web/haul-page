# T-020-02 Structure: Auto-Provision Pipeline

## New Files

### `lib/haul/ai/provisioner.ex`
Module: `Haul.AI.Provisioner`

Public API:
- `from_profile(profile :: OperatorProfile.t(), conversation_id :: String.t()) :: {:ok, result()} | {:error, step :: atom(), reason :: term()}`

Result type:
```
%{
  company: Company.t(),
  site_url: String.t(),
  tenant: String.t(),
  generated_content: map(),
  duration_ms: integer()
}
```

Internal functions:
- `validate_profile/1` — checks required fields, returns :ok or {:error, :validation, missing}
- `generate_content/1` — calls ContentGenerator.generate_all/1
- `onboard_from_profile/1` — calls Onboarding.run/1 with mapped attrs
- `apply_generated_content/3` — overlays generated content onto tenant resources
- `link_conversation/2` — links conversation to company

### `lib/haul/workers/provision_site.ex`
Module: `Haul.Workers.ProvisionSite`

- `use Oban.Worker, queue: :default, max_attempts: 3`
- `enqueue(conversation_id, profile_map)` — creates Oban job
- `perform(%Oban.Job{args: %{"conversation_id" => id, "profile" => profile_map}})` — delegates to Provisioner
- Broadcasts result via PubSub to `"provisioning:#{conversation.session_id}"`

### `test/haul/ai/provisioner_test.exs`
- Test validation (missing fields)
- Test full pipeline with sandbox adapter
- Test idempotency (run twice, same result)
- Test failure at each step

### `test/haul/workers/provision_site_test.exs`
- Test job enqueue
- Test perform delegates to Provisioner
- Test PubSub broadcast on success/failure

## Modified Files

### `lib/haul/ai/conversation.ex`
- Add `:provisioning` and `:failed` to status enum
- Add `:mark_provisioning` action (update status to :provisioning)
- Add `:mark_failed` action (update status to :failed)

### `lib/haul_web/live/chat_live.ex`
- Add `provisioning?` assign (boolean, default false)
- Subscribe to PubSub topic `"provisioning:#{session_id}"` on mount
- Add `handle_event("provision_site", ...)`:
  - Guard: profile_complete? must be true, provisioning? must be false
  - Set provisioning? = true
  - Enqueue ProvisionSite worker
  - Show "Building your site..." in chat
- Add `handle_info({:provisioning_complete, result}, ...)`:
  - Set provisioning? = false
  - Show success message with site_url and login info
- Add `handle_info({:provisioning_failed, reason}, ...)`:
  - Set provisioning? = false
  - Show error message
- Modify profile panel CTA: "Build My Site" button instead of link to /app/onboarding
  - Disabled when provisioning? is true
  - Shows spinner during provisioning

### `lib/haul/ai.ex` (domain)
- No changes needed — Provisioner doesn't need to be an Ash resource

### `config/config.exs`
- No changes needed — `:default` queue already exists

## Module Boundaries

```
ChatLive
  → ProvisionSite.enqueue(conversation_id, profile)
  ← PubSub {:provisioning_complete, result}
  ← PubSub {:provisioning_failed, reason}

ProvisionSite (Oban Worker)
  → Provisioner.from_profile(profile, conversation_id)
  → PubSub.broadcast(topic, message)

Provisioner
  → Extractor.validate_completeness(profile)
  → ContentGenerator.generate_all(profile)
  → Onboarding.run(attrs)
  → Ash actions on tenant resources (SiteConfig, Service)
  → Conversation actions (mark_provisioning, link_to_company)
```

## File Change Summary

| File | Action | Lines (est) |
|------|--------|-------------|
| lib/haul/ai/provisioner.ex | Create | ~120 |
| lib/haul/workers/provision_site.ex | Create | ~60 |
| lib/haul/ai/conversation.ex | Modify | +15 |
| lib/haul_web/live/chat_live.ex | Modify | +60 |
| test/haul/ai/provisioner_test.exs | Create | ~120 |
| test/haul/workers/provision_site_test.exs | Create | ~60 |
