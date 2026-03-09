# T-002-04 Progress — Browser QA

## Pre-flight

- Dev server was already running but returning 500 due to stale config (started before operator config was added)
- `String.replace(nil, ...)` crash on `@phone` — operator config wasn't loaded
- **Fix:** Restarted dev server (`just dev-down && just dev`). No code changes needed.
- After restart: `curl` returns HTTP 200

## Step 1: Desktop Accessibility Snapshot ✓

Navigated to `http://localhost:4000/` at default viewport.

### Verification Checklist

| Check | Result |
|-------|--------|
| H1 "Junk Hauling" | ✓ Present |
| "& Handyman Services" subtitle | ✓ Present |
| Phone "(555) 123-4567" as tel: link | ✓ `tel:5551234567` |
| "Call for a free estimate" text | ✓ Present |
| H2 "What We Do" | ✓ Present |
| Service: Junk Removal | ✓ With description |
| Service: Cleanouts | ✓ With description |
| Service: Yard Waste | ✓ With description |
| Service: Repairs | ✓ With description |
| Service: Assembly | ✓ With description |
| Service: Moving Help | ✓ With description |
| H2 "Why Hire Us" | ✓ Present |
| 6 benefit items | ✓ All 6 dash-prefixed items |
| H2 "Ready to Get Started?" | ✓ Present |
| Footer phone CTA | ✓ tel: link |
| Print button | ✓ Visible (JS enabled) |
| Email link | ✓ `mailto:hello@junkandhandy.com` |
| Eyebrow "Licensed & Insured" | ✓ Present |

**Result: ALL PASS**

## Step 2: Mobile Viewport Snapshot (375x812) ✓

Resized to 375×812 (iPhone-class viewport).

### Verification Checklist

| Check | Result |
|-------|--------|
| All sections present | ✓ Hero, Services, Why Us, Footer |
| Correct order | ✓ Top-to-bottom as expected |
| Same content as desktop | ✓ No missing elements |

**Result: ALL PASS**

## Step 3: Horizontal Overflow Check ✓

```javascript
scrollWidth: 375, innerWidth: 375, hasOverflow: false
```

No horizontal scrollbar at 375px width.

**Result: PASS**

## Step 4: Server Log Review ✓

Last 50 lines of `.dev.log`:
- All `GET /` requests returned **200**
- No 500 errors (after restart)
- No crash reports or exceptions
- Tailwind and esbuild watchers running normally

**Result: PASS**

## Summary

All acceptance criteria met. No code changes required. The only issue encountered was a stale dev server that needed restart — not a code bug.
