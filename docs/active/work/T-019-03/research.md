# T-019-03 Research: Conversation Persistence

## Current State

### ChatLive (`lib/haul_web/live/chat_live.ex`)
- Mounted at `/start` — public route, no auth, no tenant context
- Session ID: `Ecto.UUID.generate()` on every mount — **lost on refresh**
- Messages: in-memory list of `%{id, role, content}` — **lost on disconnect**
- Streaming: Task-based with `Haul.AI.Chat.stream_message/3`
- Rate limiting: `RateLimiter.check_rate({:chat, session_id}, 50, 86400)` — ETS-based, tied to session_id
- No conversation persistence, no company linking, no audit trail

### AI Module Structure (`lib/haul/ai/`)
- `Haul.AI` — behaviour + adapter pattern for BAML calls
- `Haul.AI.Chat` — behaviour for chat (Sandbox/Anthropic adapters)
- `Haul.AI.Extractor` — extracts OperatorProfile from transcript via BAML
- `Haul.AI.Prompt` — loads prompts from `priv/prompts/`
- `Haul.AI.OperatorProfile` — struct with business fields
- `Haul.AI.ProfileMapper` — converts profile → Ash resource attrs
- **No Ash domain exists for AI** — `ash_domains` in config.exs: `[Haul.Accounts, Haul.Operations, Haul.Content]`

### Multi-Tenancy
- Schema-per-tenant via AshPostgres `:context` strategy
- Tenant-scoped resources (Service, SiteConfig, etc.) require tenant context for all operations
- Company is NOT tenant-scoped — lives in public schema
- Tenant provisioned via `ProvisionTenant` change on Company creation

### Session/Cookie Handling
- Endpoint: cookie session store, key `_haul_key`, signed (not encrypted)
- TenantResolver stores `tenant_slug` in session
- LiveView reads session in mount's 2nd param (read-only after mount)
- LiveView can't write to session — need controller/plug for cookie writes

### Oban Setup
- Configured in application.ex supervision tree
- Queues: `notifications: 10, default: 5, certs: 3`
- Existing cron: `CheckDunningGrace` at 6am daily
- Worker pattern: `use Oban.Worker, queue: :name, max_attempts: N`

### Existing Oban Workers
- `CheckDunningGrace` — cron, queries companies, updates subscription status
- `ProvisionCert` — one-shot, polls external service, updates company

### Test Patterns
- DataCase for DB tests, ConnCase for HTTP/LiveView
- `create_authenticated_context/1` provisions tenant + user + token
- Chat tests use `Sandbox.set_response/1` + `assert_receive`
- Extractor tests use fixture transcripts

## Key Constraints

1. **Conversations start pre-tenant** — `/start` is public, no tenant exists yet. The resource CANNOT be tenant-scoped.
2. **LiveView can't write cookies** — session_id must be set by a plug/controller, then read by LiveView on mount.
3. **AI domain doesn't exist as Ash domain** — need to either create one or put Conversation in an existing domain.
4. **Company FK is nullable** — conversation starts anonymous, linked to company after provisioning.
5. **JSONB for messages** — Postgres array of maps, not a separate table. Simpler, adequate for ~50 messages max.
6. **No PII in logs** — conversation content in DB only, Logger must not dump message content.

## Files That Will Change

- `lib/haul_web/live/chat_live.ex` — load/save conversation, read session_id from cookie
- `lib/haul_web/router.ex` — possibly add session_id plug or controller redirect
- `config/config.exs` — add AI to ash_domains, add Oban cron entry
- `lib/haul/application.ex` — if AI domain needs registration

## Files That Will Be Created

- `lib/haul/ai/conversation.ex` — Ash resource
- `priv/repo/migrations/YYYYMMDDHHMMSS_create_conversations.exs` — migration
- `lib/haul/workers/cleanup_conversations.ex` — Oban cron worker
- `test/haul/ai/conversation_test.ex` — resource tests
- `test/haul_web/live/chat_live_test.exs` — persistence integration tests (may already exist)

## Open Questions

1. Should Conversation live in a new `Haul.AI` Ash domain or under `Haul.Accounts`?
2. How to set session_id cookie before LiveView mount? Options: plug in pipeline, or redirect through controller.
3. Should messages be stored as JSONB array or as individual rows in a messages table?
4. Rate limiting: should it key on session_id from cookie (persistent) instead of in-memory UUID?
