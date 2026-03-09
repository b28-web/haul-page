# T-019-02 Design: Live Extraction

## Decision: Inline Extraction in ChatLive

### Option A: Separate LiveComponent for profile panel
- Pro: Clean separation of concerns
- Con: Needs PubSub or shared state to communicate extraction results
- Con: Adds complexity for little benefit — profile state is tightly coupled to chat messages

### Option B: Extend ChatLive with extraction assigns + profile panel (CHOSEN)
- Pro: Simple — extraction triggered directly in `send_user_message/2`, results stored in socket assigns
- Pro: No inter-component communication needed
- Pro: Profile panel renders from assigns directly
- Con: ChatLive grows larger (but stays under 400 lines)

**Rationale:** The profile panel's lifecycle is entirely tied to the chat. Extraction runs on chat messages, results display alongside chat. A LiveComponent boundary adds plumbing without value.

## Extraction Strategy

### Trigger
After each user message, spawn a Task that runs `Extractor.extract_profile/1` on the full transcript. The Task sends `{:extraction_result, {:ok, profile}}` or `{:extraction_result, {:error, reason}}` to the LiveView.

### Debounce
Use `Process.send_after(self(), :run_extraction, 800)` with a stored timer ref. On each new user message, cancel the previous timer and set a new one. When `:run_extraction` fires, spawn the extraction Task.

This handles rapid-fire messages: only the last message in a burst triggers extraction. 800ms debounce — long enough to catch bursts, short enough to feel responsive.

### Concurrent Tasks
- `:task_ref` — existing, for chat streaming Task
- `:extraction_ref` — new, for extraction Task
- `:extraction_timer` — new, timer ref for debounce
- Both can be in flight simultaneously. They don't interact.

### Error Handling
Extraction errors: log with `Logger.warning`, do nothing in UI. Profile just stays at previous state. No flash, no error text.

## Transcript Format
Build from messages list:
```
user: Hello I run QuickHaul
assistant: Nice! What services do you offer?
user: Junk removal and cleanouts
```
Simple `"#{role}: #{content}"` per message, joined with `\n`.

## Profile Panel UI

### Layout
- Desktop (md+): 2-column flex. Chat takes `flex-1`, profile sidebar is `w-80` fixed.
- Mobile: profile card below header, collapsible via toggle button. Collapsed by default until first extraction completes.

### Panel Contents
1. **Header**: "Your Profile" with completeness text ("4 of 7 fields")
2. **Progress bar**: colored width based on completeness percentage
3. **Field list**: Each field shows label + value or "Not yet provided" in muted text
   - Business Name, Owner, Phone, Email, Service Area
4. **Services**: List of service names with category icons (or "No services yet")
5. **Differentiators**: Bullet list (or "None yet")
6. **CTA**: When all required fields present, show "Your profile is complete!" + "Create my site" button

### Animations
- `transition-all duration-300` on field values
- Fields change from `text-muted-foreground` to `text-foreground` when filled
- Progress bar width transitions smoothly

## Test Strategy

### Sandbox Adapter Issue
`Haul.AI.Sandbox` uses process dictionary — won't work from spawned Tasks. Solution: for tests, detect sandbox mode and run extraction synchronously (inline) instead of in a Task. This matches the pattern — tests don't need real async behavior for extraction.

Alternative: Make extraction Task use ETS-based sandbox. But this would require changing the AI adapter, which is out of scope.

**Chosen approach:** In the extraction spawn, if the adapter is Sandbox, call inline. This keeps test compatibility without changing adapter infrastructure. Actually simpler: just use `send(self(), :run_extraction)` in tests which runs synchronously in the test process context.

Actually, the cleanest approach: The Sandbox adapter already has a default response for `ExtractOperatorProfile`. Since extraction runs in a spawned Task and Sandbox uses process dictionary, tests need to either:
1. Set the response in the Task's process — not possible from test
2. Use a different mechanism

Best solution: Add an ETS-based override to `Haul.AI.Sandbox` (like Chat.Sandbox does), or simply accept that the default sandbox response works for most tests. For tests that need specific extraction results, we can use `Haul.AI.Sandbox.set_response/2` and run extraction inline.

**Final decision:** Keep extraction in a Task always. The Sandbox default response for ExtractOperatorProfile returns a complete profile. For tests, the extraction will use the default response (since process dict override won't propagate to Task). This is fine — we test that the profile panel renders, not specific extraction content. For targeted extraction tests, those already exist in `extractor_test.exs`.

## State Management

New socket assigns:
- `:profile` — `%OperatorProfile{}` | `nil` (initially nil)
- `:missing_fields` — `[atom()]` (initially all fields)
- `:extraction_ref` — `reference()` | `nil` (monitor ref for extraction Task)
- `:extraction_timer` — `reference()` | `nil` (timer ref for debounce)
- `:profile_complete?` — `boolean()` (derived: missing required fields == [])
- `:show_profile?` — `boolean()` (mobile toggle, default false until first extraction)
