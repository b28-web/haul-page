# T-020-05 Structure: Browser QA — AI Provision Pipeline

## Files Modified

### New
- `test/haul_web/live/provision_qa_test.exs` — End-to-end QA test module

### No other files created or modified
This is a QA-only ticket. All code under test already exists.

## Module Structure

```elixir
defmodule HaulWeb.ProvisionQATest do
  use HaulWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  # Aliases: ChatSandbox, Conversation, OperatorProfile, ServiceOffering,
  #          Provisioner, Service, SiteConfig

  # Module attribute: @profile (complete OperatorProfile)

  # Setup: clear_rate_limits, clear sandbox, on_exit tenant cleanup

  # Helper: provision_and_enter_edit_mode(conn) -> {view, result}
  #   1. Mount /start
  #   2. Create conversation
  #   3. Call Provisioner.from_profile(@profile, conv.id)
  #   4. Send :extraction_result to set profile
  #   5. Send :provisioning_complete to enter edit mode
  #   6. Return {view, result}

  # Test groups:
  #   "full pipeline" — chat → provision → preview
  #   "edit in preview" — tagline change, phone change, verify DB
  #   "go live and tenant site" — finalize → GET tenant pages → verify content
  #   "mobile preview" — toggle preview panel in edit mode
end
```

## Test Coverage Map

| Test Plan Item | Test |
|---|---|
| 1. Navigate to /start — conversation | "shows chat UI and accepts messages" |
| 2. Build my site | "provisioning enters edit mode with preview" |
| 3. Provisioning progress | "shows building message during provisioning" |
| 4. Preview with generated content | "preview panel shows site URL and iframe" |
| 5. Edit tagline in chat | "tagline edit updates SiteConfig" |
| 6. Go live | "go live finalizes session" |
| 7. Tenant landing page | "tenant landing page has generated content" |
| 8. Generated content not placeholders | "landing page shows business name and tagline" |
| 9. /scan page | "tenant scan page renders" |
| 10. /book form | "tenant booking form renders" |
| 11. Mobile preview | "mobile preview toggle works in edit mode" |
