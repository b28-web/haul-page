# T-028-03 Research: Extract LiveView Logic

## Scope

T-028-03 targets pure business logic embedded in LiveView modules. T-028-02 handles domain modules (Billing, Domains, AI, Content, Workers, Controllers). This ticket is exclusively LiveView → helper module extraction.

## LiveView Modules Surveyed

| Module | Lines | Pure functions found | Key patterns |
|--------|-------|---------------------|--------------|
| BillingLive | 367 | plan_rank, plan_name, format_price, days_until_downgrade | Plan comparison logic, price formatting |
| PaymentLive | 287 | get_field, format_amount | Duplicate price formatting, duplicate field accessor |
| GalleryLive | 545 | extract_key, next_sort_order, friendly_error, reorder | Sort order calc, storage key extraction, reorder swap |
| ServicesLive | 328 | swap_sort_order | Identical reorder to GalleryLive |
| EndorsementsLive | 359 | swap_sort_order, source_label, star_display | Identical reorder, display formatters |
| ChatLive | 934 | build_transcript, append_to_last_assistant, has_assistant_content?, deep_to_map, restore_messages, all_profile_fields | Message manipulation, struct conversion |
| BookingLive | 331 | merge_preferred_dates, get_field, friendly_error | Date merging, duplicate field accessor & error formatter |
| OnboardingLive | 443 | step_title, upload_error_to_string | Step labels, duplicate error formatter |
| AccountsLive | 251 | filter_companies, sort_companies, toggle_dir, sort_indicator, plan_badge_class | List filtering/sorting, display helpers |
| ScanLive | ~50 | get_field | Duplicate field accessor |

## Cross-Module Duplications (LiveView-scoped)

### 1. `get_field/2` — 4 identical copies
- booking_live.ex:103, payment_live.ex:118, scan_live.ex:21, page_controller.ex:40
- Pattern: struct → Map.get, map → map[field]

### 2. `friendly_error/1` / `upload_error_to_string/1` — 3 copies
- booking_live.ex:106, gallery_live.ex:264, onboarding_live.ex:401
- Same error atom → human string mapping, slightly different messages

### 3. `format_price/1` / `format_amount/1` — 2 copies
- billing_live.ex:351, payment_live.ex:121
- Same cents → "$X.XX" conversion

### 4. Reorder swap logic — 3 copies
- gallery_live.ex:225-252, services_live.ex:147-177, endorsements_live.ex:128-158
- Identical pattern: find index, compute swap index, swap sort_order via Ash update

## Extractable Pure Functions (LiveView-only)

### From BillingLive
- `plan_rank/1` — plan atom → numeric rank (line 337)
- `plan_name/1` — plan atom → display string (lines 338-342)
- `format_price/1` — cents → "$X/mo" or "Free" (lines 351-356)
- `days_until_downgrade/1` — DateTime → remaining grace days (lines 362-366)

### From PaymentLive
- `format_amount/1` — cents → "$X.XX" (lines 121-125)

### From ChatLive
- `build_transcript/1` — message list → plaintext string (lines 841-846)
- `append_to_last_assistant/2` — append text to last assistant msg (lines 848-857)
- `has_assistant_content?/1` — check last msg is non-empty assistant (lines 859-863)
- `deep_to_map/1` — recursive struct → map conversion (lines 926-933)
- `restore_messages/1` — DB format → runtime format (lines 888-898)

### From GalleryLive
- `extract_key/1` — URL → storage key (lines 218-220)
- `next_sort_order/1` — items → max sort_order + 1 (lines 261-262)

### From EndorsementsLive
- `source_label/1` — source atom → display string (lines 165-169)
- `star_display/1` — rating int → star string (lines 171-175)

### From AccountsLive
- `filter_companies/2` — case-insensitive search (lines 177-186)
- `sort_companies/3` — sort by field + direction (lines 188-200)
- `toggle_dir/1` — :asc ↔ :desc (lines 202-203)
- `sort_indicator/3` — field + current sort → arrow string (lines 205-207)
- `plan_badge_class/1` — plan atom → CSS class (lines 209-218)

### From BookingLive
- `merge_preferred_dates/1` — collapse 3 date fields → list (lines 76-85)

### From OnboardingLive
- `step_title/1` — step number → label (lines 394-399)

## Constraints

- T-028-02 is extracting domain-level pure functions (Billing, Domains, AI modules, etc.)
- This ticket must not conflict — only extract from LiveView `defp` functions
- Existing LiveView integration tests must pass unchanged
- Extracted functions take/return plain data, not sockets
- Net new: 20+ unit tests required

## Key Observations

1. Reorder logic is the biggest win — 3 identical implementations, ~30 lines each
2. `get_field/2` is trivial but appears 4 times — consolidation prevents future drift
3. ChatLive has the most extractable functions (5+) but they're already well-separated as defp helpers
4. BillingLive formatting functions are duplicated in PaymentLive
5. AccountsLive sorting/filtering is self-contained and highly testable
