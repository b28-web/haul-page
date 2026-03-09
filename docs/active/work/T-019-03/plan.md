# T-019-03 Plan: Conversation Persistence

## Step 1: Create AI Ash domain + Conversation resource

1. Create `lib/haul/ai/domain.ex` — Ash domain with Conversation resource
2. Create `lib/haul/ai/conversation.ex` — full Ash resource with all attributes, actions, identities
3. Create `lib/haul/ai/changes/append_message.ex` — change module for add_message action
4. Add `Haul.AI.Domain` to `ash_domains` in `config/config.exs`
5. Generate migration: `mix ash.codegen create_conversations`
6. Run migration: `mix ash.migrate`

**Verify:** `mix compile` succeeds. Migration creates table.

## Step 2: Write Conversation resource tests

1. Create `test/haul/ai/conversation_test.exs`
2. Test cases:
   - Create conversation with session_id
   - Duplicate session_id rejected (identity)
   - Add message appends to messages array
   - Multiple messages maintain order
   - Save extracted profile
   - Link to company sets company_id + status :completed
   - Read by session_id returns correct conversation
   - Stale active query returns only old active conversations
   - Mark abandoned changes status

**Verify:** `mix test test/haul/ai/conversation_test.exs` passes.

## Step 3: Create EnsureChatSession plug

1. Create `lib/haul_web/plugs/ensure_chat_session.ex`
2. Add plug to router — scope it to chat routes
3. Write minimal plug test or verify via ChatLive integration test

**Verify:** Visiting `/start` sets `chat_session_id` in session cookie.

## Step 4: Update ChatLive for persistence

1. Modify `mount/3`:
   - Read `chat_session_id` from session
   - Load conversation by session_id from DB
   - If exists: restore messages + message_count
   - If not: create new Conversation
2. Modify `send_user_message/2`:
   - After creating user_msg, persist to DB via add_message
3. Modify `handle_info({:ai_done}, ...)`:
   - Persist completed assistant message to DB
4. Update rate limiter key to use persistent session_id

**Verify:** Send messages, refresh page, messages restore.

## Step 5: Create CleanupConversations Oban worker

1. Create `lib/haul/workers/cleanup_conversations.ex`
2. Add to Oban cron config in `config/config.exs`
3. Create `test/haul/workers/cleanup_conversations_test.exs`
4. Test: create conversations at various ages, run worker, verify correct cleanup

**Verify:** `mix test test/haul/workers/cleanup_conversations_test.exs` passes.

## Step 6: Integration test — ChatLive persistence

1. Update/create `test/haul_web/live/chat_live_test.exs`
2. Test: session_id persisted in session cookie
3. Test: messages survive across LiveView mount (simulate reconnect)
4. Test: new session creates new conversation

**Verify:** Full test suite passes: `mix test`

## Testing Strategy

- **Unit tests:** Conversation resource CRUD, change module, cleanup worker
- **Integration tests:** ChatLive mount with existing conversation, message persistence
- **Edge cases:** empty messages, max messages, duplicate session_id, concurrent access
- **Not tested here:** Company linking (future ticket's concern), PII logging (code review)
