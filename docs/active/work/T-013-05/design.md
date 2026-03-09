# T-013-05 Design: Endorsements CRUD

## Decision Summary

Follow the ServicesLive pattern exactly: inline form, list view with reorder arrows, two-step delete confirmation. Add sort_order to Endorsement resource via migration.

## Approach: Inline Form (ServicesLive Pattern)

### Why this approach
- Endorsements have simple text fields — no uploads, no complex widgets
- ServicesLive is the proven pattern for CRUD lists with reordering
- Consistent UX across content admin pages
- Minimal new code — adapt existing pattern

### Rejected: Modal form (GalleryLive pattern)
- Modals are better for media-heavy forms with uploads
- Endorsements are text-focused, inline form is cleaner
- Less JS complexity

### Rejected: Table layout
- Would work but doesn't match the card-list pattern used by Services
- Consistency matters more than marginal layout improvement

## Resource Changes

### Add sort_order to Endorsement
- New attribute: `sort_order :integer, allow_nil? false, default 0, public? true`
- Update `:add` action to accept `sort_order`
- Update `:edit` action to accept `sort_order`
- Migration: add `sort_order` column with default 0

### No other resource changes needed
- All required attributes already exist
- Source enum already defined
- PaperTrail already configured

## LiveView Design

### State
```
tenant: string          — tenant schema name
endorsements: [Endorsement] — all endorsements sorted by sort_order
editing: nil | :new | id — current form mode
ash_form: AshPhoenix.Form | nil
form: Phoenix.HTML.Form | nil
delete_target: Endorsement | nil
source_options: [{label, value}]
```

### Events
| Event | Action |
|-------|--------|
| add | Open create form |
| edit(id) | Open edit form for endorsement |
| validate(params) | Live validate form |
| save(params) | Submit form (create or update) |
| cancel | Close form/delete dialog |
| delete(id) | Show delete confirmation |
| confirm_delete | Execute delete |
| move_up(id) | Swap with previous item |
| move_down(id) | Swap with next item |

### List Item Display
- Customer name (bold)
- Quote text excerpt (truncated, muted)
- Source badge (if present)
- Star rating display (if present)
- Featured badge (if featured)
- Inactive indicator (opacity-50 when !active)
- Reorder arrows (left side)
- Edit/Delete buttons (right side)

### Form Fields
| Field | Input Type | Required | Notes |
|-------|-----------|----------|-------|
| customer_name | text | yes | |
| quote_text | textarea | yes | 3 rows |
| source | select | no | google/yelp/direct/facebook + blank |
| star_rating | number | no | min 1, max 5 |
| date | date | no | |
| featured | checkbox | no | Show on both create and edit |
| active | checkbox | no | Edit only |

## Sidebar

Add "Endorsements" link with `hero-chat-bubble-left-right` icon in the content submenu, after Services. Also add Gallery link that's currently missing.

## Delete Strategy

Same as ServicesLive: raw SQL to delete version records first (PaperTrail FK), then delete the endorsement. No "cannot delete last" restriction — zero endorsements is valid.

## Sort Order Migration

Simple `alter table` migration adding `sort_order integer not null default 0` to endorsements table. Uses tenant migration since endorsements is multi-tenant.

## Test Strategy

Mirror ServicesLiveTest:
- Unauthenticated redirect
- Mount renders page
- Renders existing endorsements
- Add new endorsement
- Edit existing endorsement
- Delete with confirmation
- Reorder up/down
- Cancel closes form
- Validate in real-time
