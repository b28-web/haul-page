---
id: S-021
title: qa-walkthrough-report
status: open
epics: [E-003, E-006, E-010, E-011]
---

## QA Walkthrough Report

Capstone story that runs after all Playwright browser-qa tickets complete. An agent gathers every QA result, assembles a visual walkthrough using locally-stored screenshots, and produces a factfinding report for the developer covering what's new, what's working, what's tested, and what needs attention.

## Scope

- Collect all browser-qa progress.md files and extract pass/fail results
- Read all local screenshots from work artifact directories
- Produce a single walkthrough document with embedded images showing the app at each stage
- Summarize: features built, tests passing (ExUnit + Playwright), coverage gaps, bugs found during QA
- Highlight architectural decisions made during implementation that the dev should know about
- Flag anything that looks fragile, untested, or inconsistent across the QA runs
- Present as an interactive briefing — dev can ask follow-up questions
