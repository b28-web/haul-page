# T-019-01 Research: Chat LiveView

## Codebase Map

### LiveView Patterns
All LiveViews in `lib/haul_web/live/app/` follow a consistent structure:
- `use HaulWeb, :live_view`
- `mount/3` → set assigns (`:page_title`, tenant, data)
- `handle_event/3` → process user actions, return `{:noreply, socket}`
- `render/1` → `~H` sigil with Tailwind classes

Form-based LiveViews use `AshPhoenix.Form`. Chat doesn't need this — it's message-based, not form-based.

### Router Structure (`lib/haul_web/router.ex`)
- Public tenant routes at lines 33–37: `/scan`, `/book`, `/pay/:job_id` in `:tenant` live_session with `TenantHook` on_mount
- Public unauthenticated routes at lines 41–48: `/app/signup`, `/app/login` (no live_session)
- Authenticated routes at lines 51–68: `:authenticated` live_session with `AuthHooks` + admin layout

**Route placement for `/start`:** Public scope, within the `:tenant` live_session (lines 33–37). No auth required.

### AI Module Architecture (`lib/haul/ai/`)
- **`Haul.AI`** — behaviour with `call_function/2` callback. Adapter pattern: Sandbox (dev/test) vs Baml (prod).
- **`Haul.AI.Baml`** — calls `BamlElixir.Client.call/3` NIF. Synchronous, structured output only.
- **`Haul.AI.Sandbox`** — process dictionary overrides for test isolation. Default fixtures for `ExtractOperatorProfile`.
- **`Haul.AI.Prompt`** — loads from `priv/prompts/{name}.md`, strips YAML frontmatter.
- **`Haul.AI.Extractor`** — `extract_profile/1` takes transcript string, returns `{:ok, %OperatorProfile{}}`.

**Key constraint:** Current AI adapter is designed for structured extraction (BAML typed outputs), NOT free-form chat. Chat needs conversational text responses, not typed structs. BAML's `call_function` returns structured data — unsuitable for chat.

**Chat approach:** Use Anthropic Messages API directly via `Req` (already a dependency) for conversational responses. BAML is for extraction (T-019-02), not chat.

### BAML Source (`baml/main.baml`)
- Client: `claude-sonnet-4-20250514` with `env.ANTHROPIC_API_KEY`
- Functions: `ExtractName`, `ExtractOperatorProfile` — both return structured types
- No chat/conversation function defined

### Prompt System (`priv/prompts/onboarding_agent.md`)
- v1 system prompt created by T-019-04
- Loaded via `Haul.AI.Prompt.load("onboarding_agent")`
- Conversational agent persona for collecting business info
- Covers 5+ persona scenarios (terse, chatty, unsure, pricing-curious, non-English-dominant)
- Required fields: business_name, phone, email

### Rate Limiter (`lib/haul/rate_limiter.ex`)
- ETS-based GenServer with `check_rate(key, limit, window_seconds)`
- Returns `:ok` or `{:error, :rate_limited}`
- Used in SignupLive for signup rate limiting
- Ticket requires: max 50 messages per session (per-socket key, not per-IP)

### JS Hooks (`assets/js/app.js`)
- Hook registration: `hooks: {...colocatedHooks, StripePayment, AddressAutocomplete, ExternalRedirect}`
- Pattern: `mounted()` sets up listeners, `handleEvent()` for server→client events, `destroyed()` for cleanup
- Chat will need: auto-scroll hook, possibly streaming text update hook

### Layouts
- Root layout: `lib/haul_web/components/layouts/root.html.heex` — minimal, includes app.js
- Admin layout: sidebar + header (authenticated routes only)
- Chat should use root layout (no sidebar)

### CSS/Theme (`assets/css/app.css`)
- Dark theme default: `--background: 0 0% 6%`, `--foreground: 0 0% 92%`
- Card: `--card: 0 0% 10%`, Border: `--border: 0 0% 22%`
- Fonts: Oswald (display), Source Sans 3 (body)
- Tailwind utilities: `bg-background`, `text-foreground`, `bg-card`, `border-border`

### Dependencies Available
- `Req ~> 0.5` — HTTP client for Anthropic API calls
- Phoenix LiveView 1.1 — async assigns, streams available
- No WebSocket client library needed (server-side HTTP to Anthropic)

### Streaming Architecture
LiveView streaming pattern:
1. User sends message → `handle_event("send_message", ...)`
2. Spawn `Task` to call Anthropic API with streaming
3. `Req` supports streaming via `:into` option (stream response body)
4. Task sends chunks to LiveView process via `send(self(), {:ai_chunk, token})`
5. `handle_info({:ai_chunk, token}, socket)` appends token to current AI message
6. Client auto-scrolls via JS hook or `push_event`

### Conversation State
Ticket says "conversation state held in LiveView process" — no DB persistence (T-019-03).
- `socket.assigns.messages` — list of `%{role: :user | :assistant, content: text}`
- `socket.assigns.message_count` — for rate limiting (max 50)
- `socket.assigns.streaming?` — boolean, disables input during AI response

## Constraints & Risks
1. **No BAML streaming** — BamlElixir NIF is synchronous. Must use Anthropic API directly for chat.
2. **Req streaming** — `Req.get/post` with `:into` supports streaming. Need to handle SSE format (Anthropic uses `text/event-stream`).
3. **Mobile-first** — 375px width. Chat bubbles must not overflow. Input must be thumb-friendly.
4. **Session-scoped rate limit** — per LiveView process, not per IP. Resets on page reload.
5. **System prompt size** — onboarding_agent.md is substantial. Each API call sends full conversation history + system prompt.
