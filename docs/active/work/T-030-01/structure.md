# T-030-01 Structure: Audit Error Handling

## Deliverable

Single file: `docs/active/work/T-030-01/audit.md`

This is a research-only ticket. No source code files are created, modified, or deleted.

## Audit Document Structure

```
audit.md
├── Summary table (all 14 sites, one row each)
├── Detailed findings per classification
│   ├── Keep (7 sites) — brief justification each
│   ├── Narrow (3 sites) — current pattern, what to narrow to, caller impact
│   └── Fix Return (4 sites) — current return, correct return, test impact
├── Worker error propagation analysis
│   └── Per-worker: what Oban does on :ok vs {:error, _}
└── Recommendations for T-030-02 and T-030-03
    ├── Which sites T-030-02 should fix (narrow rescues)
    └── Which sites T-030-03 should fix (worker returns)
```

## Dependencies on Other Tickets

- **T-030-02** (fix-defensive-rescues) will consume the "narrow" classifications
- **T-030-03** (fix-worker-errors) will consume the "fix return" classifications

The audit.md must contain enough detail for those tickets to implement changes without re-researching.

## No Module Boundaries or Interfaces

N/A — research-only output.
