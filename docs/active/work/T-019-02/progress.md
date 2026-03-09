# T-019-02 Progress: Live Extraction

## Completed

### Step 1: Extraction assigns in mount
- Added `:profile`, `:missing_fields`, `:extraction_ref`, `:extraction_timer`, `:profile_complete?`, `:show_profile?` to mount

### Step 2: Extraction scheduling and execution
- `schedule_extraction/1` — debounce timer (800ms) with cancel-and-reschedule
- `handle_info(:run_extraction)` — spawns Task calling `Extractor.extract_profile/1`
- `handle_info({:extraction_result, ...})` — updates profile assigns on success, logs on error
- Extended `{:DOWN, ref, ...}` handler for extraction_ref crashes
- `build_transcript/1` — converts messages to "role: content\n" format
- Modified `send_user_message/2` to call `schedule_extraction`

### Step 3: Profile panel UI
- 2-column layout: chat (flex-1) + profile sidebar (w-80, desktop only)
- Mobile: collapsible profile card with toggle button in header
- `profile_panel/1` function component: header, completeness bar, field list, services, differentiators, CTA
- `profile_field/1` function component: label + value with transition classes
- Progress bar with width percentage and smooth transition

### Step 4: Profile complete CTA
- Shows "Your profile is complete!" + "Create my site" link when required fields present
- Required fields: business_name, phone, email (per ProfileMapper.missing_fields)

### Step 5: Tests
- 17 tests total, 0 failures (8 new tests added to "live extraction" describe block)
- Tests cover: profile panel rendering, completeness indicator, services list, differentiators, CTA, error handling, crash handling

## Deviations from plan
- T-019-03 agent modified ChatLive concurrently, adding conversation persistence. My extraction code integrated cleanly with their changes (they added persist_message, save_extracted_profile, load_or_create_conversation).
- The save_extracted_profile function from T-019-03 has a Jason.Encoder issue with ServiceOffering struct — not my concern, logged as warning and doesn't affect extraction display.

## Remaining
- None — all steps complete. Ready for review.
