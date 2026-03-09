# T-002-02 Structure: Print Stylesheet

## Files Modified

### 1. `assets/css/app.css`

**Section:** `@media print` block (lines 149-196)

Add rules to existing block:

```
@media print {
  /* ... existing rules unchanged ... */

  /* NEW: Remove max-width constraints for full-width print */
  [class*="max-w-"] {
    max-width: none !important;
  }

  /* NEW: Prevent sections from splitting across pages */
  section {
    break-inside: avoid;
  }

  /* NEW: Ensure SVG icons are visible */
  svg {
    color: black !important;
  }
}
```

Three additions, all inside the existing `@media print` block. No new blocks or restructuring.

### 2. `lib/haul_web/controllers/page_html/home.html.heex`

**Change 1:** Add print-only URL display in footer area (before tear-off strip)

Insert after the `print:hidden` business name paragraph (line 103-105), before the tear-off strip comment (line 107):

```heex
<%-- Print-only: show URL for printed poster --%>
<p class="hidden print:block text-sm mt-4">
  {@url} · {@phone}
</p>
```

This shows the website URL and phone number in the printed output body (above the tear-off strip).

**Change 2:** Add `print-break-avoid` to service grid items — actually not needed per design decision. Sections already get `break-inside: avoid` via CSS.

### 3. `lib/haul_web/controllers/page_controller.ex`

**Change:** Add `@url` assign to the `home` action.

```elixir
def home(conn, _params) do
  # ... existing assigns ...
  url = HaulWeb.Endpoint.url()
  render(conn, :home, ..., url: url)
end
```

Need to read the current controller to see exact assign structure.

## Files NOT Modified

- `lib/haul_web/components/layouts/root.html.heex` — No nav or chrome that needs print hiding
- `config/config.exs` — URL comes from existing endpoint config
- No new files created

## Public Interface

No new public modules, routes, or APIs. The only new template assign is `@url` (string).

## Ordering

1. CSS changes first (no dependencies)
2. Controller change (adds `@url` assign)
3. Template change (consumes `@url` assign)

Steps 1 and 2 are independent. Step 3 depends on step 2.
