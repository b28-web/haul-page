# T-019-02 Structure: Live Extraction

## Files Modified

### `lib/haul_web/live/chat_live.ex` (primary)
**New assigns in mount:**
- `:profile` → nil
- `:missing_fields` → [:business_name, :owner_name, :phone, :email, :service_area, :services, :differentiators]
- `:extraction_ref` → nil
- `:extraction_timer` → nil
- `:profile_complete?` → false
- `:show_profile?` → false

**New private functions:**
- `schedule_extraction(socket)` — cancel existing timer, set new `Process.send_after(:run_extraction, 800)`
- `build_transcript(messages)` — convert message list to "role: content\n" string
- `profile_field_count(profile, missing)` — returns {filled, total} for completeness display

**New handle_info clauses:**
- `:run_extraction` — spawn extraction Task, store monitor ref
- `{:extraction_result, {:ok, profile}}` — update :profile, :missing_fields, :profile_complete?, :show_profile?
- `{:extraction_result, {:error, reason}}` — Logger.warning, no UI change
- `{:DOWN, ref, ...}` for extraction_ref — handle crash silently

**Modified send_user_message/2:**
- After spawning chat stream, call `schedule_extraction(socket)`

**Modified render/1:**
- Wrap existing chat in 2-column flex layout
- Add profile panel component (function component, not LiveComponent)

**New function components:**
- `profile_panel(assigns)` — renders the sidebar/card with profile data
- `profile_field(assigns)` — renders a single labeled field with filled/empty state
- `completeness_bar(assigns)` — renders progress bar

### `test/haul_web/live/chat_live_test.exs` (extended)
**New test group: "live extraction"**
- Test: profile panel appears after sending message and extraction completes
- Test: completeness indicator shows correct count
- Test: profile fields update when extraction returns data
- Test: extraction errors don't show in UI
- Test: "Create my site" CTA appears when profile is complete

## Module Boundaries

```
ChatLive
├── mount/3           — init all assigns
├── render/1          — 2-column layout with chat + profile panel
├── handle_event/3    — existing (send_message, update_input)
├── handle_info/2     — existing (ai_chunk, ai_done, ai_error, DOWN)
│                     + new (run_extraction, extraction_result, DOWN for extraction)
├── send_user_message — existing + schedule_extraction
├── schedule_extraction — debounce timer management
├── build_transcript  — messages → string
├── profile_panel/1   — function component
├── profile_field/1   — function component
└── completeness_bar/1 — function component
```

## No New Files Created
All changes are within existing ChatLive module and its test file. The extraction infrastructure (Extractor, OperatorProfile, AI adapters) is already complete from T-018-03.

## Data Flow
```
User sends message
  → send_user_message (existing: spawn chat stream)
  → schedule_extraction (new: set 800ms timer)
  → [800ms passes, no new messages]
  → :run_extraction handler
  → spawn Task { build_transcript → Extractor.extract_profile → send result }
  → {:extraction_result, {:ok, profile}} handler
  → assign profile, missing_fields, profile_complete?
  → re-render profile panel
```
