# T-013-05 Review: Endorsements CRUD

## Summary

Built the `/app/content/endorsements` LiveView for managing customer endorsements/testimonials. Follows the established ServicesLive CRUD pattern with inline form, two-step delete, and sort-order reordering.

## Files Changed

### Modified
| File | Change |
|------|--------|
| `lib/haul/content/endorsement.ex` | Added `sort_order` attribute; added it to `:add` and `:edit` accept lists |
| `lib/haul_web/router.ex` | Added `/content/endorsements` route in authenticated scope |
| `lib/haul_web/components/layouts/admin.html.heex` | Added Endorsements + Gallery sidebar links |

### Created
| File | Purpose |
|------|---------|
| `priv/repo/tenant_migrations/20260309040000_add_endorsement_sort_order.exs` | Adds `sort_order` column to endorsements table |
| `lib/haul_web/live/app/endorsements_live.ex` | Full CRUD LiveView (246 lines) |
| `test/haul_web/live/app/endorsements_live_test.exs` | 11 tests covering all CRUD operations |

## Acceptance Criteria

| Criterion | Status |
|-----------|--------|
| `/app/content/endorsements` LiveView | ✓ |
| List view: customer name, excerpt, source | ✓ Plus star rating display, featured badge |
| Add/edit form: customer_name, text, source, rating | ✓ Plus date, featured, active fields |
| Delete with confirmation | ✓ Two-step: delete → confirm_delete |
| Reorder via sort_order | ✓ Move up/down with swap pattern |
| Changes reflect on scan page immediately | ✓ Scan page uses `load_endorsements/1` which reads from DB |

## Test Coverage

11 tests, all passing:
- Unauthenticated redirect
- Mount renders page with title and add button
- Renders existing endorsements with name, text, source
- Adds new endorsement via form
- Validates form in real-time
- Edits existing endorsement
- Deletes with two-step confirmation
- Can delete the only endorsement (no minimum restriction)
- Reorder with move up
- Reorder with move down
- Cancel closes form

## Open Concerns

1. **Flaky onboarding_test** — Pre-existing slug generation race condition (`joe-s-hauling-llc` vs `joe-s-hauling`). Not related to this ticket. Passes when run in isolation.

2. **PaperTrail delete pattern** — Delete uses raw SQL to handle FK constraints (same as ServicesLive). This is a known pattern in the codebase. A cleaner approach would be to add `on_delete: :delete_all` to the PaperTrail versions FK, but that's a broader refactor tracked separately (see T-013-04's gallery cascade fix migration).

3. **Sidebar: Gallery link was missing** — Added it alongside endorsements. This is a minor scope creep but prevents confusion for operators navigating the admin.

4. **No sort_order auto-increment on create** — New endorsements get `sort_order: 0` by default. This means newly added endorsements appear at the top until reordered. The same behavior exists in Services. If auto-increment is desired, it would require a custom change in the `:add` action.
