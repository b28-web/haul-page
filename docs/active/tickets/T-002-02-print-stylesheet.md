---
id: T-002-02
story: S-002
title: print-stylesheet
type: task
status: open
priority: medium
phase: done
depends_on: [T-002-01]
---

## Context

The landing page doubles as a printable poster/flyer. The React prototype has a complete print stylesheet to translate.

## Design (from prototype)

- White background, black text — strips all backgrounds to save ink
- Oswald for headings: h1 at 42pt, h2 at 22pt, font-weight 700, tracked 0.04em
- Source Sans 3 for body at 11pt, line-height 1.3
- `.no-print` class hides interactive elements (buttons, nav)
- `.print-break-avoid` prevents section splits across pages
- Full width — removes all max-width constraints
- `@page { margin: 0.3in; size: letter; }`
- Border color: `rgba(0, 0, 0, 0.35)` for cut guides
- **Tear-off strip**: 8 vertical tabs at bottom. Each tab has "JUNK & HANDY" label, "10% OFF", phone number. Tabs separated by dashed borders. Uses `writing-mode: vertical-rl`.

## Acceptance Criteria

- `@media print` rules in `assets/css/app.css` (not a separate file — Tailwind handles it)
- White bg, dark text, strip section backgrounds
- `.no-print` hides buttons, interactive elements
- Tear-off strip visible only in print (hidden on screen via `hidden print:block`)
- Headings use correct print sizes (42pt/22pt)
- Page fits on letter-size paper with 0.3in margins
- Phone number and URL visible in print output
- Tested via browser print preview
