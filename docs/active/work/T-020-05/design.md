# T-020-05 Design: Browser QA — AI Provision Pipeline

## Problem

Verify the full end-to-end AI onboarding pipeline works as a cohesive flow. Existing tests cover individual segments (chat QA in T-019-06, preview/edit in T-020-03) but not the complete path: conversation → extraction → provisioning → preview → edit → go live → tenant site renders with generated content.

## Approach: Integration Test with Real Provisioning

### Option A: Simulated provisioning (like T-019-06)
- Pro: Fast, no DB schemas to clean up
- Con: Doesn't test the actual provisioning pipeline or verify tenant site content
- **Rejected**: Misses the point of this ticket — verifying the end-to-end "magic moment"

### Option B: Full pipeline with real provisioning (like T-020-03's enter_edit_mode)
- Pro: Tests actual provisioning, content generation, tenant creation, and site rendering
- Con: Slower (creates DB schemas), needs cleanup
- **Chosen**: This is the capstone QA — it must verify the real pipeline produces a working site

### Option C: Playwright MCP browser automation
- Pro: True browser rendering, JS hooks, visual verification
- Con: Heavy setup, flaky, overkill for server-rendered content verification
- **Rejected**: LiveViewTest + controller tests verify the same content. No JS-dependent rendering logic in the pipeline.

## Test Structure

### 1. Full pipeline test (chat → provision → verify)
- Send message to trigger extraction
- Call Provisioner.from_profile directly (bypass Oban for determinism)
- Simulate provisioning_complete via send/2
- Verify edit mode activated with preview panel

### 2. Edit flow test (in context of full pipeline)
- After provisioning, send edit messages
- Verify edits apply and content updates in DB
- Verify preview panel reflects changes

### 3. Go live + tenant site verification
- Click "Looks good — go live!"
- Make separate HTTP requests to tenant site pages
- Verify landing page has generated content (business name, tagline, services)
- Verify /scan page renders
- Verify /book page renders

### 4. Mobile UX test
- Verify mobile toggle works for preview panel in edit mode
- Verify finalization message renders

## Key Design Decisions

1. **Direct Provisioner.from_profile call** instead of Oban job — deterministic, no async timing issues
2. **Separate conn for tenant pages** — tenant resolver needs subdomain, which we simulate via assigns
3. **Verify DB state** after each edit — ensures edits actually persisted, not just UI updates
4. **Single test module** — all tests share the same setup pattern (create conversation, provision, enter edit mode)
5. **Tenant cleanup in on_exit** — drop all tenant_% schemas to prevent test pollution
