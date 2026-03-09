# T-013-05 Research: Endorsements CRUD

## Objective

Build `/app/content/endorsements` LiveView for managing customer endorsements/testimonials.

## Existing Endorsement Resource

**File:** `lib/haul/content/endorsement.ex`

Ash resource with AshPaperTrail, schema-per-tenant multitenancy.

### Attributes
| Name | Type | Required | Default | Notes |
|------|------|----------|---------|-------|
| id | uuid | yes | auto | Primary key |
| customer_name | string | yes | — | |
| quote_text | string | yes | — | |
| star_rating | integer | no | nil | Constrained 1–5 |
| source | Endorsement.Source enum | no | nil | google, yelp, direct, facebook |
| date | date | no | nil | |
| featured | boolean | yes | false | |
| active | boolean | yes | true | |
| inserted_at | utc_datetime | auto | — | |
| updated_at | utc_datetime | auto | — | |

### Relationships
- `belongs_to :job` (optional) — link to Operations.Job

### Actions
- `:read` (default)
- `:destroy` (default)
- `:add` (create) — accepts customer_name, quote_text, star_rating, source, date, featured
- `:edit` (update) — accepts customer_name, quote_text, star_rating, source, date, featured, active

### Missing: sort_order
The ticket requires "Reorder via sort_order" but the Endorsement resource has **no sort_order attribute**. Services and GalleryItem both have `sort_order :integer`. This needs to be added.

## Source Enum

**File:** `lib/haul/content/endorsement/source.ex`
Values: `:google`, `:yelp`, `:direct`, `:facebook`

## Content Domain

**File:** `lib/haul/content.ex`
Endorsement and Endorsement.Version already registered. No changes needed.

## Existing CRUD Patterns

### ServicesLive (`lib/haul_web/live/app/services_live.ex`) — Primary Pattern
- Inline form (not modal)
- States: `editing` (nil, :new, or id), `delete_target`, `ash_form`, `form`
- Events: add, edit, validate, save, cancel, delete, confirm_delete, move_up, move_down
- AshPhoenix.Form for create/update with tenant
- Delete: raw SQL to handle PaperTrail FK constraints (delete versions first, then record)
- Reorder: swap_sort_order helper swaps sort_order values between two items
- Load: `Ash.read!(Resource, tenant: tenant)` — returns all items

### GalleryLive (`lib/haul_web/live/app/gallery_live.ex`) — Reference for uploads/modal
- Modal-based form (not needed for endorsements)
- File uploads via LiveView `allow_upload`
- Toggle active status inline

### SiteConfigLive — Single record create-or-update (different pattern, not applicable)

## Router

**File:** `lib/haul_web/router.ex` (lines 56–63)
Route needed: `live "/content/endorsements", App.EndorsementsLive`
Goes inside the `:authenticated` live_session scope under `/app`.

## Admin Layout

**File:** `lib/haul_web/components/layouts/admin.html.heex`
Content submenu (lines 37–50) currently has Site Settings and Services.
Need to add Endorsements link. Gallery link also appears to be missing from sidebar
but has a route — that's a separate concern.

## Test Patterns

**File:** `test/haul_web/live/app/services_live_test.exs`
- `use HaulWeb.ConnCase, async: false`
- Setup: `create_authenticated_context(role: :owner)`, `log_in_user`, `cleanup_tenants`
- Tests: mount, render existing, add, validate, edit, delete with confirm, cannot delete last, reorder up/down, cancel
- Helper: `create_service/2` creates records directly via Ash.Changeset

## Content Helpers

**File:** `lib/haul_web/content_helpers.ex`
`load_endorsements/1` already exists — loads active endorsements for scan page.
Admin LiveView loads all (active + inactive) directly via `Ash.read!`.

## Constraints & Assumptions

1. Endorsement needs `sort_order` attribute + migration to support reordering
2. The `:add` and `:edit` actions need to accept `sort_order`
3. No "cannot delete last" constraint (unlike Services) — operators can have zero endorsements
4. PaperTrail versions table `endorsements_versions` must be cleaned up before delete (FK constraint)
5. Changes reflect on scan page immediately via `load_endorsements/1` (already filters by `active`)
6. No file uploads needed — simpler than Gallery
