# T-028-03 Structure: File Changes

## New Files

### `lib/haul_web/helpers.ex`
```elixir
defmodule HaulWeb.Helpers do
  def get_field/2
  def friendly_upload_error/1
  def merge_preferred_dates/1
end
```

### `lib/haul/formatting.ex`
```elixir
defmodule Haul.Formatting do
  def format_price/1         # cents → "$X/mo" or "Free"
  def format_amount/1        # cents → "$X.XX"
  def plan_name/1            # atom → display string
  def plan_rank/1            # atom → numeric rank
  def plan_badge_class/1     # atom → CSS class
  def star_display/1         # rating → "★★★☆☆"
  def source_label/1         # atom → "Google" etc
  def days_until_downgrade/1 # DateTime → integer days
end
```

### `lib/haul/ai/message.ex`
```elixir
defmodule Haul.AI.Message do
  def build_transcript/1
  def append_to_last_assistant/2
  def has_assistant_content?/1
  def deep_to_map/1
  def restore_messages/1
end
```

### `lib/haul/sortable.ex`
```elixir
defmodule Haul.Sortable do
  def find_swap_index/3   # (items, id, direction) → {:ok, idx, swap_idx} | :error
  def next_sort_order/1   # items → integer
end
```

### `lib/haul/admin/account_helpers.ex`
```elixir
defmodule Haul.Admin.AccountHelpers do
  def filter_companies/2
  def sort_companies/3
  def toggle_dir/1
  def sort_indicator/3
end
```

### Test Files (new)
- `test/haul_web/helpers_test.exs`
- `test/haul/formatting_test.exs`
- `test/haul/ai/message_test.exs`
- `test/haul/sortable_test.exs`
- `test/haul/admin/account_helpers_test.exs`

## Modified Files

### LiveViews — replace defp with module calls
- `lib/haul_web/live/app/billing_live.ex` — remove plan_rank, plan_name, format_price, days_until_downgrade; import/alias Haul.Formatting
- `lib/haul_web/live/payment_live.ex` — remove get_field, format_amount; alias HaulWeb.Helpers, Haul.Formatting
- `lib/haul_web/live/app/gallery_live.ex` — remove friendly_error, extract_key, next_sort_order, simplify reorder; alias helpers
- `lib/haul_web/live/app/services_live.ex` — simplify reorder with Sortable
- `lib/haul_web/live/app/endorsements_live.ex` — remove source_label, star_display, simplify reorder; alias helpers
- `lib/haul_web/live/chat_live.ex` — remove build_transcript, append_to_last_assistant, has_assistant_content?, deep_to_map, restore_messages; alias Haul.AI.Message
- `lib/haul_web/live/booking_live.ex` — remove get_field, friendly_error, merge_preferred_dates; alias helpers
- `lib/haul_web/live/app/onboarding_live.ex` — remove upload_error_to_string; alias HaulWeb.Helpers
- `lib/haul_web/live/scan_live.ex` — remove get_field; alias HaulWeb.Helpers
- `lib/haul_web/controllers/page_controller.ex` — remove get_field; alias HaulWeb.Helpers
- `lib/haul_web/live/admin/accounts_live.ex` — remove filter/sort/toggle/indicator/badge functions; alias helpers

## Ordering
1. Create helper modules first (no dependencies)
2. Create test files
3. Modify LiveViews one at a time, running targeted tests after each
4. Full suite at end
