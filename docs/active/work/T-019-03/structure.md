# T-019-03 Structure: Conversation Persistence

## New Files

### `lib/haul/ai/domain.ex`
- Ash domain module `Haul.AI.Domain`
- Resources: `[Haul.AI.Conversation]`
- Minimal — just the domain declaration

### `lib/haul/ai/conversation.ex`
- Ash resource `Haul.AI.Conversation`
- Domain: `Haul.AI.Domain`
- Data layer: `AshPostgres.DataLayer`
- Table: `conversations` (public schema, NOT tenant-scoped)
- Attributes:
  - `uuid_primary_key :id`
  - `session_id` — `:uuid`, required, public
  - `messages` — `{:array, :map}`, default `[]`, public
  - `extracted_profile` — `:map`, allow_nil, public
  - `status` — `:atom`, constraints `[one_of: [:active, :completed, :abandoned]]`, default `:active`
  - `company_id` — `:uuid`, allow_nil (manual FK, not Ash relationship for now since Company is in different domain)
  - `create_timestamp :inserted_at`
  - `update_timestamp :updated_at`
- Identities: unique on `:session_id`
- Actions:
  - `create :start` — accept `[:session_id]`, sets defaults
  - `read :by_session_id` — get by session_id, filter
  - `read :stale_active` — filter active + older than N days
  - `read :old_abandoned` — filter abandoned + older than N days
  - `update :add_message` — accepts message map, appends to messages array via change
  - `update :save_profile` — accept `[:extracted_profile]`
  - `update :link_to_company` — accept `[:company_id]`, set status to `:completed`
  - `update :mark_abandoned` — set status to `:abandoned`
  - `destroy :cleanup` — default destroy

### `lib/haul/ai/changes/append_message.ex`
- Ash change module for `:add_message` action
- Reads current messages, appends new message with timestamp
- Validates message has role + content

### `lib/haul_web/plugs/ensure_chat_session.ex`
- Plug module
- `init/1` — no opts
- `call/2` — checks `get_session(conn, "chat_session_id")`; if nil, generates UUID and `put_session`
- Added to `:browser` pipeline in router (or scoped to chat routes)

### `lib/haul/workers/cleanup_conversations.ex`
- `use Oban.Worker, queue: :default, max_attempts: 3`
- `perform/1`:
  1. Read stale active conversations (>30 days), mark abandoned
  2. Read old abandoned conversations (>30 days), destroy each
  3. Return `:ok`

### `priv/repo/migrations/YYYYMMDDHHMMSS_create_conversations.exs`
- Create `conversations` table in public schema
- Columns: id (uuid PK), session_id (uuid, unique index), messages (jsonb, default []), extracted_profile (jsonb), status (varchar), company_id (uuid, nullable, FK references companies), inserted_at, updated_at
- Index on `company_id`
- Index on `status, inserted_at` (for cleanup queries)

### `test/haul/ai/conversation_test.exs`
- Resource tests: create, add_message, save_profile, link_to_company, by_session_id
- Cleanup action tests: stale_active query, mark_abandoned, destroy

### `test/haul/workers/cleanup_conversations_test.exs`
- Worker test: creates conversations at various ages/statuses, runs worker, verifies correct ones cleaned up

### `test/haul_web/live/chat_live_test.exs` (may exist already)
- Persistence tests: send message → refresh → messages still there
- Session tests: session_id persists across requests

## Modified Files

### `config/config.exs`
- Add `Haul.AI.Domain` to `:ash_domains` list
- Add `CleanupConversations` to Oban cron config

### `lib/haul_web/router.ex`
- Add `EnsureChatSession` plug to the pipeline or scope serving `/start`

### `lib/haul_web/live/chat_live.ex`
- `mount/3`: read `chat_session_id` from session → call `Conversation.by_session_id`
  - If found: restore messages, session_id, message_count from DB
  - If not found: create new Conversation with session_id
- `send_user_message/2`: after building user_msg, persist via `Conversation.add_message`
- `handle_info({:ai_done}, socket)`: persist completed assistant message via `Conversation.add_message`
- Keep in-memory message list for UI responsiveness; DB is source of truth for recovery

## Unchanged Files

- `lib/haul/ai.ex` — no changes, behaviour module stays as-is
- `lib/haul/ai/chat.ex` — no changes to chat adapter interface
- `lib/haul/ai/extractor.ex` — no changes
- `lib/haul/application.ex` — no changes (Oban picks up config automatically)

## Module Boundaries

- `Haul.AI.Conversation` — Ash resource, all DB operations
- `Haul.AI.Changes.AppendMessage` — pure data transform (append to list)
- `HaulWeb.Plugs.EnsureChatSession` — HTTP concern only
- `Haul.Workers.CleanupConversations` — background job, calls Conversation actions
- `HaulWeb.ChatLive` — orchestrator, calls Conversation for persistence
