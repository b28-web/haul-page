# T-019-02 Plan: Live Extraction

## Step 1: Add extraction assigns to mount
- Add `:profile`, `:missing_fields`, `:extraction_ref`, `:extraction_timer`, `:profile_complete?`, `:show_profile?` to socket in mount/3
- Verify: mount still works, no regressions

## Step 2: Add extraction scheduling and execution
- `schedule_extraction/1` — cancel old timer, set new 800ms timer
- `handle_info(:run_extraction, socket)` — spawn Task calling Extractor.extract_profile
- `handle_info({:extraction_result, result}, socket)` — update assigns on success, log on error
- `handle_info({:DOWN, ref, ...})` — extend existing to handle extraction_ref crashes
- `build_transcript/1` — convert messages to string
- Modify `send_user_message/2` to call `schedule_extraction`
- Verify: extraction runs after message, debounces on rapid messages

## Step 3: Add profile panel UI
- Restructure render to 2-column layout (chat left, profile right on md+)
- `profile_panel/1` function component: header, completeness bar, fields, services, differentiators, CTA
- `profile_field/1` helper: renders label + value with transition classes
- `completeness_bar/1` helper: progress bar with width percentage
- Mobile: collapsible card, toggle button in header
- Verify: panel renders with empty state, updates when profile arrives

## Step 4: Add "profile complete" CTA
- When `profile_complete?` is true, show success message + "Create my site" button
- CTA links to `/app/onboarding` (or emits event — downstream ticket will handle)
- Verify: CTA appears when all required fields present

## Step 5: Write tests
- Test profile panel renders after extraction completes
- Test completeness indicator shows correct count
- Test extraction errors don't leak to UI
- Test CTA appears when profile is complete
- Test debounce behavior (send multiple messages rapidly)
- Run full test suite to check no regressions

## Step 6: Verify and polish
- Run `mix test` — all tests pass
- Manual check: render output looks correct
- Commit

## Testing Strategy
- LiveView tests: mount, send message, wait for extraction, check profile panel content
- Sandbox adapter returns default complete profile — tests verify panel renders with data
- For error case: would need to override sandbox, but since extraction runs in Task (process dict won't propagate), test the error path by checking that missing profile state is handled gracefully
- No integration tests needed — extraction is already tested in extractor_test.exs
