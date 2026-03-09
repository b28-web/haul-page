# T-002-04 Structure — Browser QA

## Overview

This is a verification-only ticket. No files are created or modified in the application codebase. All output is documentation in the work directory.

## Files Modified

None (unless bugs are discovered during QA).

## Files Created

All in `docs/active/work/T-002-04/`:

| File | Purpose |
|------|---------|
| `research.md` | Codebase mapping for QA targets |
| `design.md` | QA approach and verification strategy |
| `structure.md` | This file — file-level plan |
| `plan.md` | Step-by-step execution sequence |
| `progress.md` | Real-time QA results and findings |
| `review.md` | Summary of QA outcomes |

## External Dependencies

- **Dev server** must be running on `localhost:4000` (`just dev`)
- **Playwright MCP** tools must be available in the agent session

## Verification Checklist

The QA checks map to specific template regions:

### Desktop Verification Points

```
home.html.heex line mapping:
├── Hero section (lines 3–42)
│   ├── Eyebrow text: "Licensed & Insured"
│   ├── H1: "Junk Hauling"
│   ├── Subtitle: "& Handyman Services"
│   ├── Phone tel: link
│   └── Email mailto: link
├── Services grid (lines 45–57)
│   ├── H2: "What We Do"
│   └── 6 service items with titles
├── Why Hire Us (lines 60–73)
│   ├── H2: "Why Hire Us"
│   └── 6 dash-prefixed items
└── Footer CTA (lines 76–133)
    ├── H2: "Ready to Get Started?"
    ├── Phone CTA button
    └── Print button (JS-enabled)
```

### Mobile Verification Points

Same content as desktop, plus:
- No horizontal scrollbar (`scrollWidth <= viewportWidth`)
- All sections render in correct vertical order
- Grid collapses appropriately (2-col services instead of 3)

### Server Health Points

- No 500-level responses in `.dev.log`
- Page load returns HTTP 200

## Conditional: Bug Fix Structure

If bugs are found during QA:
- Fix in the relevant source file (template, CSS, controller)
- Document the fix in `progress.md` with before/after
- Minimal changes only — no refactoring
