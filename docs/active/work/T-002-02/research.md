# T-002-02 Research: Print Stylesheet

## Current State

The print stylesheet is ~80% implemented. Both the CSS (`assets/css/app.css:149-196`) and the HTML template (`lib/haul_web/controllers/page_html/home.html.heex`) contain print-specific code.

## What Exists

### CSS (`assets/css/app.css:149-196`)

```
@media print {
  @page { margin: 0.3in; size: letter; }        ✓ matches spec
  body { background: white; color: black;
         font: 11pt Source Sans 3; line-height: 1.3 }  ✓ matches spec
  h1 { font: 700 42pt Oswald; letter-spacing: 0.04em } ✓ matches spec
  h2 { font: 700 22pt Oswald }                         ✓ matches spec
  h3 { color: black }                                  ✓
  a { color: black; text-decoration: none }             ✓
  section/footer/div/main { background: transparent }   ✓
  p { color: black }                                    ✓
  * { border-color: rgba(0,0,0,0.35) }                 ✓ matches spec
}
```

### HTML Template (`home.html.heex`)

- `print:hidden` on CTA button container (line 85)
- `print:hidden` on footer business name line (line 103)
- `hidden print:block` on tear-off strip (line 108) — shows only in print
- Tear-off strip: 8 tabs, `writing-mode: vertical-rl`, business name, coupon text, phone
- Print button with progressive JS enhancement (lines 94-100, 132-134)

## Gaps vs. Acceptance Criteria

### 1. No max-width removal for print
**Spec says:** "Full width — removes all max-width constraints"
**Current:** All sections have `max-w-4xl mx-auto`. No CSS rule removes these in print.
**Impact:** Content will be constrained to ~896px instead of using full letter width (~7.9in = ~758px at 96dpi). Actually at 96dpi letter is ~7.9in usable (8.5 - 0.6in margins). The `max-w-4xl` is 56rem = 896px. In print, the browser uses points not pixels. This constraint may or may not clip — but the spec explicitly says remove it.

### 2. No `.no-print` class defined
**Spec says:** "`.no-print` class hides interactive elements (buttons, nav)"
**Current:** Uses Tailwind `print:hidden` variant instead. Functionally equivalent but the ticket AC explicitly names `.no-print`.
**Assessment:** The Tailwind `print:hidden` approach is idiomatic and correct. The `.no-print` in the ticket description refers to the React prototype's approach. Since the AC says "in `assets/css/app.css`" and we use Tailwind, the `print:hidden` variant is the right translation. No change needed here — just document the decision.

### 3. No `.print-break-avoid` class
**Spec says:** "`.print-break-avoid` prevents section splits across pages"
**Current:** No `break-inside: avoid` rules exist.
**Impact:** Service cards and sections could split across pages during print.

### 4. URL not shown in print output
**AC says:** "Phone number and URL visible in print output"
**Current:** Phone is visible in hero and tear-off strip. No URL/website address is displayed in print.
**Impact:** Printed poster has no website URL for people to visit.

### 5. Footer text hidden in print
**Current:** The `<p>` with business name + service area at line 103 has `print:hidden`.
**Assessment:** This might be intentional (tear-off strip replaces it) but the phone/URL visibility AC suggests some contact info should remain visible in the main body, not just the tear-off tabs.

## Architecture Notes

- **Tailwind 4** with `print:` variant prefix — generates `@media print { ... }` rules
- **No separate print CSS file** — AC requires rules in `app.css` (already satisfied)
- **DaisyUI themes** — the `data-theme` attribute and OKLch colors are irrelevant in print (overridden by `!important` rules)
- **Heroicons** — SVG-based, render as inline SVG in HTML. Should print fine but may need `fill: black` or `stroke: black` for visibility
- **Google Fonts** — loaded via `@import url(...)`. Print will use system fonts if web fonts aren't cached. The `font:` shorthand in print rules hardcodes the font family as fallback.

## File Inventory

| File | Role | Print-relevant? |
|------|------|----------------|
| `assets/css/app.css` | All styles including print | Primary target |
| `lib/haul_web/controllers/page_html/home.html.heex` | Landing page template | Needs URL display, break-avoid classes |
| `lib/haul_web/components/layouts/root.html.heex` | Root layout | May need print rules for nav/chrome |
| `lib/haul_web/controllers/page_controller.ex` | Controller | May need `@url` assign |

## Constraints

- All print rules must live in `assets/css/app.css` (per AC)
- Tailwind `print:` variant is the idiomatic approach for element-level visibility
- Custom `@media print` block handles global overrides
- No JavaScript should be required for print layout (progressive enhancement only)
