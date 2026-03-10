# T-029-01 Structure — Document Test Tiers

## Files to Create

### `docs/knowledge/test-architecture.md` (new, ~120 lines)

Sections:
1. Header + purpose (3 lines)
2. 3-Tier Overview table (10 lines)
3. Decision Tree (10 lines)
4. Tier 1: Unit Tests — pattern + example (20 lines)
5. Tier 2: Resource Tests — pattern + example (20 lines)
6. Tier 3: Integration Tests — pattern + example (20 lines)
7. Factory Usage (15 lines)
8. setup_all vs setup (10 lines)
9. When async: true is safe (8 lines)
10. Anti-patterns (15 lines)

## Files to Modify

### `CLAUDE.md` — § Test Targeting

Insert after the "### Rules" section heading (before rule 1):

```
### Test tiers

| Tier | Test case | What it tests | Speed |
|------|-----------|---------------|-------|
| 1 — Unit | `ExUnit.Case, async: true` | Pure functions, no DB | <100ms |
| 2 — Resource | `Haul.DataCase, async: false` | Ash actions + DB | 100ms–1s |
| 3 — Integration | `HaulWeb.ConnCase, async: false` | HTTP/LiveView + full stack | 500ms–3s |

Default to the lowest viable tier. Unit > Resource > Integration. See `docs/knowledge/test-architecture.md` for decision tree and examples.
```

### `.just/system.just` — `_llm` recipe

Add to Conventions section (after "Test targeting:" line):

```
- Test tiers: Tier 1 (ExUnit.Case, async: true, pure functions) > Tier 2 (DataCase, Ash+DB) > Tier 3 (ConnCase, HTTP/LiveView). Default to lowest viable. See docs/knowledge/test-architecture.md.
```

### `docs/knowledge/rdspi-workflow.md` — Review phase

Add to Review phase description, after "Flag critical issues that need human attention.":

```
Verify new tests are at the lowest viable tier (Unit > Resource > Integration).
```

## No Files Deleted

This is a documentation-only ticket.

## Ordering

1. Create `test-architecture.md` first (canonical reference)
2. Update CLAUDE.md (references the new doc)
3. Update system.just (references the new doc)
4. Update rdspi-workflow.md (standalone change)

Steps 2–4 are independent of each other but all depend on step 1 existing.
