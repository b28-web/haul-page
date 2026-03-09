# T-019-03 Design: Conversation Persistence

## Decision 1: Where does the Conversation resource live?

### Option A: New `Haul.AI` Ash domain
- Create `Haul.AI` as a proper Ash domain with Conversation as its first resource
- Register in `ash_domains` config
- Pro: Clean domain separation, AI concerns isolated
- Con: Module name collision — `Haul.AI` already exists as a behaviour module

### Option B: Rename existing `Haul.AI` behaviour, create `Haul.AI` domain
- Rename `Haul.AI` (behaviour) to `Haul.AI.Client` or similar
- Create `Haul.AI` as Ash domain
- Con: Breaks existing callers (Extractor, tests)

### Option C: Create `Haul.Conversations` Ash domain
- Separate domain name, no collision
- Pro: Simple, no renames needed
- Con: One-resource domain feels thin

**Decision: Option A with namespace adjustment.** Create the Ash domain as `Haul.AIDomain` (or similar) to avoid collision with the existing `Haul.AI` module. Actually — Ash domains can have any name. Use `Haul.AI.Domain` as the Ash domain module. The existing `Haul.AI` module is a plain Elixir module, not a namespace conflict. `Haul.AI.Domain` lives alongside `Haul.AI.Chat`, `Haul.AI.Extractor`, etc.

**Final: `Haul.AI.Domain`** — Ash domain containing `Haul.AI.Conversation`.

## Decision 2: Session ID persistence mechanism

### Option A: Plug that generates/reads session_id
- Add a plug to the `:browser` pipeline that ensures `chat_session_id` exists in session
- LiveView reads it from session on mount
- Pro: Simple, works with existing session infrastructure
- Con: Sets cookie on every page load (minor overhead)

### Option B: Controller redirect before ChatLive
- Route `/start` to a controller that sets session_id then redirects to `/start/chat`
- Con: Extra hop, visible redirect, more complex routing

### Option C: Generate session_id in plug only for `/start` route
- Scoped plug — only runs on chat routes
- Pro: No overhead on other routes
- Con: Slightly more complex routing

**Decision: Option A.** A simple plug in the `:browser` pipeline. Tiny overhead (one session read per request). Session cookie is already being set anyway. The plug checks if `chat_session_id` exists; if not, generates UUID and puts it in session.

## Decision 3: Message storage format

### Option A: JSONB array column
- Single `messages` column as `{:array, :map}` in Postgres
- Each message: `%{"role" => "user", "content" => "...", "timestamp" => "..."}`
- Pro: Simple schema, single read/write, no joins
- Con: Must read+write entire array to append (50 msgs max, trivially small)

### Option B: Separate `messages` table
- `conversation_id` FK, indexed
- Pro: Individual message CRUD, easier querying
- Con: Overkill for max 50 messages, more complex, more migrations

**Decision: Option A.** JSONB array. The ticket specifies max 50 messages. The entire conversation is always loaded at once. Individual message queries are never needed.

## Decision 4: Conversation resource — tenant-scoped or public?

Conversations start BEFORE any tenant exists. The user is chatting to set up their business — no Company, no tenant schema yet.

**Decision: Public schema (not tenant-scoped).** Like Company, Conversation lives in the public schema. The `company_id` FK links it to a Company after provisioning. No multitenancy block in the resource.

## Decision 5: Cleanup worker

### Option A: Oban cron job
- Runs daily, queries for old abandoned conversations, deletes them
- Pro: Consistent with existing pattern (CheckDunningGrace)
- Con: None meaningful

### Option B: Postgres partitioning / TTL
- Con: Overkill for this scale

**Decision: Option A.** Oban cron job `CleanupConversations`, runs daily. Marks conversations older than 30 days with status `:active` as `:abandoned`, deletes conversations older than 30 days with status `:abandoned`.

Actually, re-reading the AC: "Conversations older than 30 days with status :abandoned are cleaned up." So the cleanup only deletes abandoned ones older than 30 days. We also need a way to mark conversations as abandoned — a conversation is abandoned if it's `:active` and older than 30 days with no recent activity. Simplify: the cron job finds `:active` conversations older than 30 days, marks them `:abandoned`, then deletes already-abandoned conversations older than 30 days.

## Decision 6: Linking conversation to Company

After tenant provisioning (signup flow), the conversation needs to be linked to the newly created Company. This happens in the onboarding/signup flow (T-015-02 or T-020-02), not in this ticket. This ticket provides the action (`link_to_company`) and the test proving it works. The actual call site is a future ticket's concern.

## Architecture Summary

```
Haul.AI.Domain (new Ash domain)
└── Haul.AI.Conversation (public schema resource)
    ├── session_id (UUID, unique index)
    ├── messages ({:array, :map} JSONB)
    ├── extracted_profile (:map, nullable)
    ├── status (:atom — :active, :completed, :abandoned)
    ├── company_id (UUID FK → companies, nullable)
    └── timestamps

HaulWeb.Plugs.EnsureChatSession (new plug)
├── Reads chat_session_id from session
└── Generates + stores UUID if missing

HaulWeb.ChatLive (modified)
├── Mount: read session_id from session → load conversation from DB
├── send_message: persist user msg + assistant msg to DB
└── Resume: restore messages from DB on reconnect

Haul.Workers.CleanupConversations (new Oban cron worker)
└── Daily: abandon stale, delete old abandoned
```
