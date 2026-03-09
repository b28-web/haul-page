---
id: T-006-02
story: S-006
title: mdex-rendering
type: task
status: open
priority: high
phase: done
depends_on: [T-006-01]
---

## Context

Wire up MDEx for markdown → HTML rendering. Page resources store markdown in `body` and cache rendered HTML in `body_html`, re-rendered on every `:edit` action.

## Acceptance Criteria

- `mdex` added to mix.exs deps
- Page `:edit` action change function renders `body` → `body_html` via `MDEx.to_html/2`
- Extensions enabled: tables, footnotes, strikethrough (GFM baseline)
- Page `:draft` action also renders body_html on create
- Template helper or component for rendering `body_html` safely (`raw/1` or `Phoenix.HTML.raw/1`)
- Test: create a Page with markdown body, verify body_html contains correct HTML
- Test: update body, verify body_html is re-rendered
