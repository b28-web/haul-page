# T-005-04 Structure — Browser QA for Scan Page

## Overview

No application code changes. This ticket produces browser QA verification artifacts only. The implementation consists of Playwright MCP interactions documented in progress.md.

## Files Modified

None. This is a QA-only ticket.

## Files Created

| File | Purpose |
|------|---------|
| `docs/active/work/T-005-04/research.md` | Codebase research |
| `docs/active/work/T-005-04/design.md` | QA approach decision |
| `docs/active/work/T-005-04/structure.md` | This file |
| `docs/active/work/T-005-04/plan.md` | Ordered test steps |
| `docs/active/work/T-005-04/progress.md` | Test execution log with results |
| `docs/active/work/T-005-04/review.md` | Summary of findings |

## QA Verification Sequence

```
1. Ensure dev server running (mix phx.server on :4000)
2. Playwright: navigate to http://localhost:4000/scan
3. Playwright: snapshot — verify hero section content
4. Playwright: snapshot — verify gallery section
5. Playwright: snapshot — verify endorsements section
6. Playwright: snapshot — verify footer CTA
7. Playwright: resize to 375x812
8. Playwright: snapshot — verify mobile layout
9. Check: no server errors
10. Document all findings in progress.md
```

## Dependencies

- Dev server must be running on port 4000
- Playwright MCP configured in `.mcp.json`
- No database needed (scan page uses JSON content files)

## Boundaries

- Read-only verification — no code changes to the application
- If bugs are found, they are documented in review.md for separate fix tickets
- QR endpoint (`/scan/qr`) already covered by unit tests; not re-tested here
