# T-019-03 Review: Conversation Persistence

## Summary

Implemented conversation persistence for the AI chat onboarding flow. Conversations survive page refreshes via a session cookie + database storage. Includes a cleanup worker for abandoned conversations and the ability to link conversations to companies post-signup.

## Files Created

| File | Purpose |
|------|---------|
| `lib/haul/ai/domain.ex` | Ash domain `Haul.AI.Domain` — container for Conversation resource |
| `lib/haul/ai/conversation.ex` | Ash resource with session_id, messages (JSONB array), extracted_profile, status, company_id |
| `lib/haul/ai/changes/append_message.ex` | Change module that appends timestamped messages to the JSONB array |
| `lib/haul_web/plugs/ensure_chat_session.ex` | Plug that ensures `chat_session_id` UUID exists in the session cookie |
| `lib/haul/workers/cleanup_conversations.ex` | Oban cron worker (3am daily) — marks stale active as abandoned, deletes old abandoned |
| `priv/repo/migrations/20260309050724_create_conversations.exs` | Migration creating `conversations` table with indexes |
| `test/haul/ai/conversation_test.exs` | 15 resource tests — CRUD, identity, queries, status transitions |
| `test/haul/workers/cleanup_conversations_test.exs` | 4 worker tests — stale marking, deletion, age filtering |

## Files Modified

| File | Change |
|------|--------|
| `config/config.exs` | Added `Haul.AI.Domain` to `ash_domains`, added `CleanupConversations` to Oban cron |
| `lib/haul_web/router.ex` | Added `EnsureChatSession` plug to `:browser` pipeline |
| `lib/haul_web/live/chat_live.ex` | Mount loads/creates conversation from cookie; messages persisted on send/complete; profile saved to conversation |

## Test Coverage

- **602 tests, 0 failures** (up from ~258 baseline + other tickets' additions)
- **New tests: 19** (15 conversation resource + 4 cleanup worker)
- **Existing tests: all passing** — no regressions in chat_live or any other test files

### Coverage Gaps

- No dedicated LiveView integration test for "refresh resumes conversation" — the existing chat_live tests don't test cross-mount persistence. This is because `Phoenix.LiveViewTest` doesn't easily simulate cookie-persisted sessions across separate `live()` calls without additional setup.
- No test for the `EnsureChatSession` plug in isolation — it's implicitly tested via ChatLive tests.

## Acceptance Criteria Checklist

- ✅ Ash resource `Haul.AI.Conversation` with all specified fields (session_id, messages, extracted_profile, status, company_id)
- ✅ Session_id stored in browser cookie (via `EnsureChatSession` plug)
- ✅ Page refresh with valid session_id resumes conversation (mount reads from DB)
- ✅ `link_to_company` action provided for tenant provisioning (sets company_id + status :completed)
- ✅ Cleanup Oban cron job for conversations older than 30 days with status :abandoned
- ✅ Messages include role, content, timestamp
- ✅ No PII in server logs — conversation content stays in database; Logger calls only log error reasons

## Design Decisions

1. **Public schema, not tenant-scoped** — conversations start before any tenant exists. company_id is nullable FK, linked post-provisioning.
2. **JSONB array for messages** — max 50 messages per conversation; simpler than a separate table, always loaded as a whole.
3. **`Haul.AI.Domain`** — new Ash domain to avoid collision with existing `Haul.AI` behaviour module.
4. **`EnsureChatSession` in `:browser` pipeline** — runs on all browser requests (tiny overhead), ensures session_id available to any LiveView.
5. **`deep_to_map/1`** — needed because `OperatorProfile` contains nested `ServiceOffering` structs that don't implement `Jason.Encoder`.

## Open Concerns

1. **Conversation reload on mount doesn't restore profile state** — if a user refreshes, their messages are restored but the extracted profile panel will be empty until the next extraction runs. Could add profile restoration from `conversation.extracted_profile` in mount.
2. **Rate limiter keys** — still using in-memory session_id for rate limiting. Since session_id now persists across refreshes, this is better than before, but the ETS-based rate limiter resets on server restart.
3. **Concurrent writes** — if a user sends messages rapidly, the `add_message` change reads the current messages array and appends. In theory, two concurrent updates could race. In practice, messages are sequential (user waits for response) so this is unlikely.
4. **Tenant migration cleanup** — the auto-generated tenant migration `20260309050720_create_conversations.exs` was deleted because it contained column additions from other tickets' resource changes. The resource snapshots were regenerated.
