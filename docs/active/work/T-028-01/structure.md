# T-028-01 Structure: Logic Audit

## Deliverable

Single file: `docs/active/work/T-028-01/audit.md`

## File Structure

```
audit.md
├── Summary (counts, category breakdown)
├── Ash Resources & Domain Modules
│   ├── Haul.Billing (6 functions)
│   ├── Haul.Domains (2 functions)
│   ├── Haul.Onboarding (5 functions)
│   ├── Haul.AI.CostTracker (4 functions)
│   ├── Haul.AI.Extractor (3 functions)
│   ├── Haul.AI.Prompt (2 functions)
│   ├── Haul.AI.ContentGenerator (1 function)
│   ├── Haul.Content.Seeder (2 functions)
│   ├── Haul.Content.Page (1 function — deduplicated)
│   ├── Haul.Storage (1 function)
│   ├── Haul.Accounts.Company (1 function — slug)
│   ├── Haul.Accounts.Changes.ProvisionTenant (1 function)
│   └── Haul.Notifications.BookingEmail (6 functions)
├── LiveView Modules
│   ├── BillingLive (3 functions)
│   ├── PaymentLive (1 function)
│   ├── EndorsementsLive (2 functions)
│   ├── OnboardingLive (1 function)
│   ├── AccountsLive (5 functions)
│   ├── BookingLive (1 function)
│   ├── ChatLive (4 functions)
│   └── GalleryLive (3 functions)
├── Controllers
│   ├── QRController (2 functions)
│   └── BillingWebhookController (3 functions)
├── Workers
│   └── ProvisionSite (3 functions)
├── Duplications (cross-module duplication inventory)
└── Priority Ranking (top 20 by impact)
```

## Entry Format

Each entry follows this template:
```
### `Module.function/arity`
- **File:** path:line
- **Does:** one-line description
- **Category:** Pure | DB-read | Tightly-coupled
- **Coverage:** Unit-tested | Integration-only | None
- **Difficulty:** Trivial | Moderate | Hard
- **Dependencies:** list of external calls (or "none")
- **Downstream:** T-028-02 | T-028-03
```

## No Code Changes

This ticket produces documentation only. No files in `lib/` or `test/` are modified.
