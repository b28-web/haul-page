# T-017-03 Structure — Browser QA for Custom Domain Flow

## Files

### Created
- `test/haul_web/live/app/domain_qa_test.exs` — Browser QA test module

### Modified
- None

### Deleted
- None

## Module Design

### `HaulWeb.App.DomainQATest`

```
use HaulWeb.ConnCase, async: false
import Phoenix.LiveViewTest

setup:
  on_exit → cleanup_tenants()

helpers:
  authenticated_conn/2 — create or use context, log in
  set_company_plan/2 — update company subscription_plan + stripe fields

describe blocks:
  "domain lifecycle (Pro operator)" — full add → CNAME → verify → remove flow
  "starter tier gating" — upgrade prompt, no form, billing link
  "pre-set domain states" — pending/provisioning/active rendering
  "domain validation" — invalid/valid/normalization
  "remove domain flow" — modal open/cancel/confirm
  "PubSub status transition" — simulate domain_status_changed
  "authentication" — unauthenticated redirect
```

## Dependencies
- `HaulWeb.ConnCase` — test setup, authenticated context creation
- `Phoenix.LiveViewTest` — LiveView test helpers
- `Haul.Accounts.Company` — company model for assertions
- `Ash` — changeset updates for plan/domain setup
