# T-002-02 Design: Print Stylesheet

## Problem

Four gaps between current implementation and acceptance criteria:
1. Max-width constraints not removed in print
2. No `break-inside: avoid` for page break prevention
3. No URL shown in print output
4. Heroicon SVGs may not be visible in print (color inheritance)

## Approach Options

### Option A: All fixes in `@media print` block + minimal template changes

Add CSS rules to the existing `@media print` block in `app.css`:
- Remove max-width: `max-width: none !important` on sections
- Add break-inside: `break-inside: avoid` on sections and service cards
- Force SVG icon colors: `fill: black` / `stroke: black`

Add a print-only URL display in the template using `hidden print:block`.

**Pros:** Minimal changes, all in expected locations, follows existing patterns.
**Cons:** None significant.

### Option B: Tailwind `print:` utilities only (no custom CSS)

Use Tailwind classes exclusively: `print:max-w-none`, `print:break-inside-avoid`, etc.

**Pros:** Pure utility-class approach.
**Cons:** Clutters HTML with many print-specific classes. Tailwind 4 may not have all needed utilities (e.g., `print:break-inside-avoid` isn't standard). The `@page` rule can't be expressed as a utility class.

### Option C: Separate print stylesheet

Create `assets/css/print.css` and import it.

**Pros:** Clean separation.
**Cons:** Violates AC ("not a separate file — Tailwind handles it").

## Decision: Option A

Hybrid approach using the existing `@media print` block for global rules and Tailwind `print:` classes for element-level visibility. This is what's already in place — we just fill the gaps.

### Specific Design Decisions

#### Max-width removal
Add to `@media print`:
```css
.mx-auto { margin-left: 0; margin-right: 0; }
[class*="max-w-"] { max-width: none; }
```
Using attribute selector to catch all max-width utility classes. This is a global print rule — every constrained container should expand.

#### Break avoidance
Add to `@media print`:
```css
section { break-inside: avoid; }
```
Sections are the natural page-break boundary. Individual service cards within the grid don't need it — they're small enough to fit.

#### URL display
Add a `hidden print:block` element in the footer area showing the website URL. The URL should come from the controller as a new `@url` assign (derived from the endpoint config or a runtime env var).

For the prototype implementation, we can hardcode a placeholder or derive it from the `HaulWeb.Endpoint` URL config. However, since operator config is via runtime env vars, the simplest approach is to add a `url` key to the config, or derive it from the endpoint.

**Decision:** Use `HaulWeb.Endpoint.url()` to get the base URL at render time. Pass as `@url` assign from PageController.

#### Heroicon visibility
SVG icons use `currentColor` by default. The print CSS already forces `color: black !important` on containing elements. As long as the SVGs inherit color, they should print fine. The `stroke-1` class on service icons sets stroke-width but not stroke color — it inherits from `currentColor`.

**Verification needed:** Check that Heroicons in this project use `currentColor` for stroke/fill.

**Decision:** Add a defensive rule: `svg { color: black !important; }` in print block. Low risk, handles edge cases.

#### `.no-print` class
Not adding a separate `.no-print` class. The Tailwind `print:hidden` approach is functionally identical and idiomatic for Tailwind 4. The `.no-print` mentioned in the ticket design section refers to the React prototype's convention, not a requirement for the Phoenix implementation. The AC says "`.no-print` hides buttons, interactive elements" — `print:hidden` satisfies this intent.

## Rejected

- **Option B** rejected: Would require adding 5+ print classes to each section in the template. The `@media print` block is cleaner for global rules.
- **Option C** rejected: Violates the AC explicitly.
- **Adding `@url` from env var**: Unnecessary when `Endpoint.url()` provides it. The endpoint URL is already configured per-environment.
- **Print-specific heading size classes**: Not needed — the `@media print` block already overrides with `font: 700 42pt Oswald`. Template classes are screen-only.
