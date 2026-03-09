# T-009-03 Structure — Browser QA for Address Autocomplete

## Files

This is a QA-only ticket. No source files created or modified.

### Artifacts produced

| File | Purpose |
|------|---------|
| `docs/active/work/T-009-03/research.md` | Codebase mapping |
| `docs/active/work/T-009-03/design.md` | Test approach decision |
| `docs/active/work/T-009-03/structure.md` | This file |
| `docs/active/work/T-009-03/plan.md` | Step-by-step test plan |
| `docs/active/work/T-009-03/progress.md` | Test execution log |
| `docs/active/work/T-009-03/review.md` | Final assessment |

### Screenshots (local only, gitignored)

| File | Content |
|------|---------|
| `docs/active/work/T-009-03/autocomplete-dropdown.png` | Dropdown visible with suggestions |
| `docs/active/work/T-009-03/autocomplete-selected.png` | Address populated after selection |

## Dependencies

- Dev server running on port 4000 (confirmed up)
- Playwright MCP configured in `.mcp.json`
- Sandbox places adapter active (default in dev)
- Tenant `junk-and-handy` provisioned (from T-003-04 QA session)

## Test structure

Seven sequential steps mapped to ticket acceptance criteria:

1. **Page load + field presence** — Navigate, snapshot, verify address field has hook attributes
2. **Autocomplete trigger** — Type "123 Main", wait for debounce, snapshot dropdown
3. **Suggestion selection (mouse)** — Click first suggestion, verify input populated
4. **Keyboard navigation** — Clear, retype, use arrow keys + enter
5. **ARIA accessibility** — Verify combobox/listbox roles from snapshot
6. **Graceful degradation** — Manual address input, form submission
7. **Server health** — Check logs for errors

## Verification criteria per acceptance item

| Acceptance criteria | Test step | Pass condition |
|---|---|---|
| Autocomplete dropdown appears on input | Step 2 | `role="listbox"` element visible with ≥1 option |
| Selecting suggestion populates address | Steps 3, 4 | Input value contains full address string |
| Form works without autocomplete | Step 6 | Manual address submits successfully |
| Accessible: listbox role, keyboard navigable | Steps 4, 5 | ARIA attributes present, keyboard selection works |
| No server errors | Step 7 | No 500 errors in logs or console |
