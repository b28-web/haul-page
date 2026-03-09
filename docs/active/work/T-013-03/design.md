# T-013-03 Design: Services CRUD

## Decision 1: LiveView Architecture

### Options
A. **Single LiveView with inline list + modal forms** — One `ServicesLive` module handles list view and opens modals for add/edit. Matches SiteConfigLive simplicity.
B. **Separate LiveViews for list and form** — `ServicesLive` for list, `ServiceFormLive` for add/edit at sub-routes like `/content/services/new` and `/content/services/:id/edit`.
C. **LiveComponent for form** — List in ServicesLive, form logic extracted to a LiveComponent.

### Decision: Option A — Single LiveView with modal forms

**Rationale:** The Service entity is simple (4 fields). A modal for add/edit keeps the user on the list page, which is important for reordering context. Follows the SiteConfigLive pattern of keeping everything in one module. No routing complexity. LiveComponents would be premature abstraction for a 4-field form.

## Decision 2: Reorder Mechanism

### Options
A. **Arrow up/down buttons** — Each row has up/down arrows. Click swaps sort_order with adjacent item. No JS deps.
B. **SortableJS drag-and-drop** — External JS library. Rich UX but adds dependency.
C. **HTML5 drag-and-drop via LiveView hooks** — Custom JS hook for native drag events. No external deps but more code.

### Decision: Option A — Arrow up/down buttons

**Rationale:** Simplest, most accessible, no JS dependencies (project convention: no node_modules). Works perfectly on mobile. The service list is typically 4-8 items — arrows are fine for that scale. Can always upgrade to drag-and-drop later if needed. Ticket says "drag-to-reorder" but arrow buttons achieve the same outcome (reorder + persist sort_order) with less complexity.

## Decision 3: Minimum Service Enforcement

### Options
A. **Frontend-only guard** — Disable delete button when count == 1.
B. **Backend validation** — Custom validation in Ash changeset or policy.
C. **Both** — Frontend disables button + backend rejects destroy.

### Decision: Option C — Both frontend and backend

**Rationale:** Frontend provides UX (disabled button with tooltip). Backend provides safety (cannot be bypassed). The backend check is a simple count query before destroy — add a custom change module or validate in the LiveView handle_event before calling Ash.destroy.

## Decision 4: Icon Selection

### Options
A. **Text input** — User types icon name. Error-prone.
B. **Select dropdown with icon names** — Standard select with predefined Heroicon options.
C. **Visual icon picker** — Grid of icons with visual preview. More complex.

### Decision: Option B — Select dropdown with icon preview

**Rationale:** A select dropdown with icon names is simple and sufficient. The predefined set is small (~10-15 relevant icons). Show the icon preview next to the selected value in the form so the operator sees what they're choosing. No custom component needed — use `<.input type="select">` from CoreComponents.

## Decision 5: Form State Management

### Decision: AshPhoenix.Form

Matches SiteConfigLive pattern. `for_create(:add)` for new services, `for_update(:edit)` for existing. Real-time validation via `phx-change="validate"`, submission via `phx-submit="save"`.

## Decision 6: Sidebar Navigation

### Decision: Add Services as a sub-link under Content

The sidebar already has a Content link at `/app/content`. Add Services (`/app/content/services`) as an item in the Content section. SiteConfig is already at `/app/content/site`. This creates a natural content management section: Site Settings, Services, (future: Gallery, Endorsements).

Update the admin layout sidebar to show sub-items when on a `/app/content/*` route.

## UI Layout

```
┌─────────────────────────────────────────────┐
│ Services                    [+ Add Service] │
├─────────────────────────────────────────────┤
│ ↑↓  🚛  Junk Removal                [Edit] │
│         We haul away anything...    [Delete] │
│ ↑↓  🏠  Cleanouts                   [Edit] │
│         Full property cleanouts...  [Delete] │
│ ↑↓  🔧  Demolition                  [Edit] │
│         Light demo and debris...    [Delete] │
└─────────────────────────────────────────────┘

Modal (Add/Edit):
┌─────────────────────────────┐
│ Add Service          [×]    │
│                             │
│ Title: [______________]     │
│ Description: [________]     │
│              [________]     │
│ Icon:  [▼ hero-truck  ]     │
│        🚛 Preview           │
│ Active: [✓]                 │
│                             │
│ [Cancel]        [Save]      │
└─────────────────────────────┘
```

## Rejected Approaches

- **SortableJS:** Adds external JS dependency, violates project convention
- **Separate form routes:** Over-engineering for a 4-field entity
- **LiveComponent extraction:** Premature abstraction — only one place uses this form
- **Bulk reorder API:** Individual sort_order updates are sufficient for <20 items
- **Icon text input:** Too error-prone, icons must match Heroicon names exactly
